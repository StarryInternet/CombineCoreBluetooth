//
//  MockPeripheral.swift
//  CombineCoreBluetooth
//
//  Created by Nick Brook on 05/09/2023.
//

import Foundation
import Combine
import CoreBluetooth

public typealias AdvertiserPublisher = AnyPublisher<(advertisementData: AdvertisementData, rssi: Double), Never>

public protocol MockPeripheralDelegate: AnyObject {
    func mockPeripheralHandleReadValue(forCharacteristic characteristic: CBCharacteristic) async throws -> Data
    func mockPeripheralHandleWriteValue(forCharacteristic characteristic: CBCharacteristic, value: Data, writeType: CBCharacteristicWriteType) async throws -> Void
    func mockPeripheralHandleSetNotifyValue(forCharacteristic characteristic: CBCharacteristic, enabled: Bool) async throws -> Void
}

public class MockPeripheralDelegateDefaultImplementaton: MockPeripheralDelegate {
    let throwing: Bool
    private init(throwing: Bool) {
        self.throwing = throwing
    }
    public static let silent = MockPeripheralDelegateDefaultImplementaton(throwing: false)
    public static let throwing = MockPeripheralDelegateDefaultImplementaton(throwing: true)
    public func mockPeripheralHandleReadValue(forCharacteristic characteristic: CBCharacteristic) async throws -> Data {
        if throwing {
            throw CBATTError(CBATTError.readNotPermitted)
        }
        return Data()
    }
    public func mockPeripheralHandleWriteValue(forCharacteristic characteristic: CBCharacteristic, value: Data, writeType: CBCharacteristicWriteType) async throws {
        if throwing {
            throw CBATTError(CBATTError.writeNotPermitted)
        }
    }
    public func mockPeripheralHandleSetNotifyValue(forCharacteristic characteristic: CBCharacteristic, enabled: Bool) async throws {
        if throwing {
            throw CBATTError(CBATTError.writeNotPermitted)
        }
    }
}

public class MockPeripheral {
    public weak var delegate: MockPeripheralDelegate? = MockPeripheralDelegateDefaultImplementaton.silent
    
    private(set) public var peripheral: Peripheral!
    
    public static func basicAdvertiser(
        advertisementInterval: TimeInterval = 1,
        advertisementData: AdvertisementData = AdvertisementData(),
        advertisementRSSIGenerator: @escaping (_ eventNumber: Int) -> Double = { _ in Double.random(in: -100...0) }
    ) -> AdvertiserPublisher {
        var eventNumber: Int = 0
        return Timer
            .publish(every: advertisementInterval, on: .main, in: .default)
            .autoconnect()
            .map({ _ in
                eventNumber += 1
                return (advertisementData, advertisementRSSIGenerator(eventNumber))
            })
            .eraseToAnyPublisher()
    }
    @Published public var advertiser: AdvertiserPublisher
    
    @Published public var discoverable = true
    @Published public var connectable = true
    
    @Published public var name: String?
    @Published var state: CBPeripheralState = .disconnected {
        didSet {
            self.discoveredServices = nil
            self.discoveredCharacteristics.removeAll()
        }
    }
    @Published public var services: [CBService]? = nil {
        didSet {
            let oldServices = self.discoveredServices
            self.discoveredServices = nil
            if let oldServices {
                self.invalidatedServicesSubject.send(oldServices)
            }
        }
    }
    @Published public var rssi: Double = 0
    public var advertisementData: AdvertisementData?
    public var maximumWriteWithResponseValueLength = 512
    public var maximumWriteWithoutResponseValueLength = 512
    @Published public var canSendWriteWithoutResponse = true
    public var ancsAuthorized = false
    
    private var discoveredServices: [CBService]? = nil
    private var discoveredCharacteristics: [CBService: [CBCharacteristic]] = [:]
    
    private let didDiscoverServicesSubject: any Subject<([CBService], Error?), Never> = PassthroughSubject()
    private let didDiscoverCharacteristicsSubject: any Subject<(CBService, Error?), Never> = PassthroughSubject()
    private let didUpdateValueForCharacteristicSubject: any Subject<(CBCharacteristic, Error?), Never> = PassthroughSubject()
    private let didWriteValueForCharacteristicSubject: any Subject<(CBCharacteristic, Error?), Never> = PassthroughSubject()
    private let didUpdateNotificationStateSubject: any Subject<(CBCharacteristic, Error?), Never> = PassthroughSubject()
    private let invalidatedServicesSubject: any Subject<[CBService], Never> = PassthroughSubject()
    
    
    public func updateValueForCharacteristic(characteristic: CBCharacteristic, value: Data) {
        (characteristic as? CBMutableCharacteristic)?.value = value
        didUpdateValueForCharacteristicSubject.send((characteristic, nil))
    }
    
    let asyncQueue = DispatchQueue.global(qos: .utility)
    
    public init(name: String?, identifier: UUID = UUID(), advertiser: AdvertiserPublisher = basicAdvertiser()) {
        self.name = name
        self.advertiser = advertiser
        peripheral = Peripheral.unimplemented(
        name: name,
        identifier: identifier,
        state: { self.state },
        services: { self.services },
        canSendWriteWithoutResponse: { self.canSendWriteWithoutResponse },
        ancsAuthorized: { self.ancsAuthorized },
        readRSSI: { self.rssi = self.rssi },
        discoverServices: { uuids in
            self.asyncQueue.async {
                if let uuids {
                    if let services = self.services {
                        let discovered = services.filter({ uuids.contains($0.uuid) })
                        self.discoveredServices = (discovered + (self.discoveredServices ?? [])).uniqued()
                        self.didDiscoverServicesSubject.send((discovered, nil))
                    } else {
                        self.discoveredServices = []
                        self.didDiscoverServicesSubject.send(([], nil))
                    }
                } else {
                    self.discoveredServices = self.services
                    self.didDiscoverServicesSubject.send((self.discoveredServices ?? [], nil))
                }
            }
        },
//        discoverIncludedServices: <#T##([CBUUID]?, CBService) -> Void#>,
        discoverCharacteristics: { uuids, service in
            self.asyncQueue.async {
                if let uuids {
                    if let characteristics = service.characteristics {
                        let discovered = characteristics.filter({ uuids.contains($0.uuid) })
                        self.discoveredCharacteristics[service] = (discovered + (self.discoveredCharacteristics[service] ?? [])).uniqued()
                        self.didDiscoverCharacteristicsSubject.send((service, nil))
                    } else {
                        self.discoveredCharacteristics[service] = nil
                    }
                } else {
                    self.discoveredCharacteristics[service] = service.characteristics
                    self.didDiscoverCharacteristicsSubject.send((service, nil))
                }
            }
        },
        readValueForCharacteristic: { characteristic in
            Task {
                do {
                    guard let delegate = self.delegate else {
                        throw CBATTError(.requestNotSupported)
                    }
                    let data = try await delegate.mockPeripheralHandleReadValue(forCharacteristic: characteristic)
                    self.updateValueForCharacteristic(characteristic: characteristic, value: data)
                } catch {
                    self.didUpdateValueForCharacteristicSubject.send((characteristic, error))
                }
            }
        },
        maximumWriteValueLength: { writeType in writeType == .withResponse ? self.maximumWriteWithResponseValueLength : self.maximumWriteWithoutResponseValueLength },
        writeValueForCharacteristic: { data, characteristic, writeType in
            Task {
                do {
                    guard let delegate = self.delegate else {
                        throw CBATTError(.requestNotSupported)
                    }
                    try await delegate.mockPeripheralHandleWriteValue(forCharacteristic: characteristic, value: data, writeType: writeType)
                    self.didWriteValueForCharacteristicSubject.send((characteristic, nil))
                } catch {
                    self.didWriteValueForCharacteristicSubject.send((characteristic, error))
                }
            }
        },
        setNotifyValue: { enabled, characteristic in
            Task {
                do {
                    guard let delegate = self.delegate else {
                        throw CBATTError(.requestNotSupported)
                    }
                    try await delegate.mockPeripheralHandleSetNotifyValue(forCharacteristic: characteristic, enabled: enabled)
                    self.didUpdateNotificationStateSubject.send((characteristic, nil))
                } catch {
                    self.didUpdateNotificationStateSubject.send((characteristic, error))
                }
            }
        },
//        discoverDescriptors: <#T##(CBCharacteristic) -> Void#>,
//        readValueForDescriptor: <#T##(CBDescriptor) -> Void#>,
//        writeValueForDescriptor: <#T##(Data, CBDescriptor) -> Void#>,
//        openL2CAPChannel: <#T##(CBL2CAPPSM) -> Void#>,
        didReadRSSI: self.$rssi.map({ Result<Double, any Error>.success($0) }).eraseToAnyPublisher(),
        didDiscoverServices: self.didDiscoverServicesSubject.eraseToAnyPublisher(),
//        didDiscoverIncludedServices: <#T##AnyPublisher<(CBService, Error?), Never>#>,
        didDiscoverCharacteristics: self.didDiscoverCharacteristicsSubject.eraseToAnyPublisher(),
        didUpdateValueForCharacteristic: self.didUpdateValueForCharacteristicSubject.eraseToAnyPublisher(),
        didWriteValueForCharacteristic: self.didWriteValueForCharacteristicSubject.eraseToAnyPublisher(),
        didUpdateNotificationState: self.didUpdateNotificationStateSubject.eraseToAnyPublisher(),
//        didDiscoverDescriptorsForCharacteristic: <#T##AnyPublisher<(CBCharacteristic, Error?), Never>#>,
//        didUpdateValueForDescriptor: <#T##AnyPublisher<(CBDescriptor, Error?), Never>#>,
//        didWriteValueForDescriptor: <#T##AnyPublisher<(CBDescriptor, Error?), Never>#>,
//        didOpenChannel: <#T##AnyPublisher<(L2CAPChannel?, Error?), Never>#>,
        isReadyToSendWriteWithoutResponse: self.$canSendWriteWithoutResponse.filter({ $0 }).map({ _ in Void() }).eraseToAnyPublisher(),
        nameUpdates: self.$name.eraseToAnyPublisher(),
        invalidatedServiceUpdates: self.invalidatedServicesSubject.eraseToAnyPublisher()
        )
    }
}

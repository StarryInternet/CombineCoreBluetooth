//
//  MockPeripheral.swift
//  CombineCoreBluetooth
//
//  Created by Nick Brook on 05/09/2023.
//

import Foundation
import Combine
import CoreBluetooth

/// A publisher type for advertisement packets
public typealias AdvertiserPublisher = AnyPublisher<(advertisementData: AdvertisementData, rssi: Double), Never>

/// A delegate protocol for the `MockPeripheral`
public protocol MockPeripheralDelegate: AnyObject {
    /// Handle a value read on the peripheral
    /// - Parameter characteristic: The characteristic read from
    /// - Returns: The data to respond with
    /// - Throws: A `CBError` or `CBATTError`
    func mockPeripheralHandleReadValue(forCharacteristic characteristic: CBCharacteristic) async throws -> Data
    
    /// Handle a value write on the peripheral
    /// - Parameter characteristic: The characteristic read from
    /// - Parameter value: The value written
    /// - Parameter writeType: The value write type
    /// - Throws: A `CBError` or `CBATTError`
    func mockPeripheralHandleWriteValue(forCharacteristic characteristic: CBCharacteristic, value: Data, writeType: CBCharacteristicWriteType) async throws
    
    /// Handle a set notify value call
    /// - Parameters:
    ///   - characteristic: The characteristic that notifications are being enabled/disabled on
    ///   - enabled: If the notifications are enabled/disabled
    func mockPeripheralHandleSetNotifyValue(forCharacteristic characteristic: CBCharacteristic, enabled: Bool) async throws
    
    /// Handle a descriptor read on the peripheral
    /// - Parameter descriptor: The characteristic read from
    /// - Returns: The data to respond with
    /// - Throws: A `CBError` or `CBATTError`
    func mockPeripheralHandleReadValue(forDescriptor descriptor: CBDescriptor) async throws -> Data
    
    /// Handle a descriptor write on the peripheral
    /// - Parameter descriptor: The characteristic read from
    /// - Parameter value: The value written
    /// - Throws: A `CBError` or `CBATTError`
    func mockPeripheralHandleWriteValue(forDescriptor descriptor: CBDescriptor, value: Data) async throws
}

/// Default implementations of the delegate for convenience
public class MockPeripheralDelegateDefaultImplementaton: MockPeripheralDelegate {
    let throwing: Bool
    private init(throwing: Bool) {
        self.throwing = throwing
    }
    
    /// A silent delegate, which does nothing when handling requests
    public static let silent = MockPeripheralDelegateDefaultImplementaton(throwing: false)
    /// A throwing delegate, which throws when handling requests with "not permitted" errors
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
    public func mockPeripheralHandleReadValue(forDescriptor descriptor: CBDescriptor) async throws -> Data {
        if throwing {
            throw CBATTError(CBATTError.readNotPermitted)
        }
        return Data()
    }
    public func mockPeripheralHandleWriteValue(forDescriptor descriptor: CBDescriptor, value: Data) async throws {
        if throwing {
            throw CBATTError(CBATTError.writeNotPermitted)
        }
    }
}

public class MockPeripheral {
    /// A delegate for the mock. Defaults to a silent delegate which does nothing on requests
    public weak var delegate: MockPeripheralDelegate? = MockPeripheralDelegateDefaultImplementaton.silent
    
    private(set) public var peripheral: Peripheral!
    
    // User parameters used to respond to requests
    
    /// The delay in handling requests
    public var handlingDelay: TimeInterval = 1
    
    /// Create a basic advertiser based on the parameters provided
    /// - Parameters:
    ///   - advertisementInterval: The interval between advertisements
    ///   - advertisementData: The data to send
    ///   - advertisementRSSIGenerator: A function which generates the next RSSI value
    /// - Returns: An advertiser that can be set to the mock
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
    
    /// An advertiser that publishes advertisement packets
    @Published public var advertiser: AdvertiserPublisher
    
    /// If the peripheral is discoverable
    @Published public var discoverable = true
    /// If the peripheral is connectable
    @Published public var connectable = true
    /// The name of the peripheral
    @Published public var name: String?
    /// The state of the peripheral
    @Published var state: CBPeripheralState = .disconnected {
        didSet {
            self.discoveredServices = nil
            self.discoveredIncludedServices.removeAll()
        }
    }
    /// The services that the peripheral publishes
    @Published public var services: [CBService]? = nil {
        didSet {
            let oldServices = self.discoveredServices
            self.discoveredServices = nil
            if let oldServices {
                self.invalidatedServicesSubject.send(oldServices)
            }
        }
    }
    /// The included services that the peripheral publishes
    @Published public var includedServices: [CBService: [CBService]]? = nil {
        didSet {
            let oldServices = self.discoveredIncludedServices
            self.discoveredIncludedServices.removeAll()
            if oldServices.count > 0 {
                self.invalidatedServicesSubject.send(oldServices.flatMap { $0.value })
            }
        }
    }
    /// The current RSSI value of the peripheral. Only used for readRSSI calls, not for advertisement packets
    @Published public var rssi: Double = 0
    /// The maximum write with response value length to return
    public var maximumWriteWithResponseValueLength = 512
    /// The maximum write without response value length to return
    public var maximumWriteWithoutResponseValueLength = 512
    /// If the peripheral can accept write without response writes
    @Published public var canSendWriteWithoutResponse = true
    /// If ANCS is authorized
    public var ancsAuthorized = false
    
    public var openL2CAPChannelError: Error?
    
    // Properties updated from requests to the mock
    
    /// The services that have been discovered on the peripheral
    private var discoveredServices: [CBService]? = nil
    /// The included services that have been discovered on the peripheral
    private var discoveredIncludedServices: [CBService: [CBService]] = [:]
    
    // Subjects
    private let didDiscoverServicesSubject: any Subject<([CBService], Error?), Never> = PassthroughSubject()
    private let didDiscoverIncludedServicesSubject: any Subject<(CBService, Error?), Never> = PassthroughSubject()
    private let didDiscoverCharacteristicsSubject: any Subject<(CBService, Error?), Never> = PassthroughSubject()
    private let didDiscoverDescriptorsSubject: any Subject<(CBCharacteristic, Error?), Never> = PassthroughSubject()
    private let didUpdateValueForCharacteristicSubject: any Subject<(CBCharacteristic, Error?), Never> = PassthroughSubject()
    private let didWriteValueForCharacteristicSubject: any Subject<(CBCharacteristic, Error?), Never> = PassthroughSubject()
    private let didUpdateValueForDescriptorSubject: any Subject<(CBDescriptor, Error?), Never> = PassthroughSubject()
    private let didWriteValueForDescriptorSubject: any Subject<(CBDescriptor, Error?), Never> = PassthroughSubject()
    private let didUpdateNotificationStateSubject: any Subject<(CBCharacteristic, Error?), Never> = PassthroughSubject()
    private let didOpenL2CAPChannelSubject: any Subject<(L2CAPChannel?, Error?), Never> = PassthroughSubject()
    private let invalidatedServicesSubject: any Subject<[CBService], Never> = PassthroughSubject()
    
    let asyncQueue = DispatchQueue.global(qos: .utility)
    
    /// Perform a handler after a delay
    /// - Parameter handler: The handler to perform
    private func handle(_ handler: @escaping () -> Void) {
        asyncQueue.asyncAfter(deadline: .now() + self.handlingDelay, execute: handler)
    }
    
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
            self.handle {
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
        discoverIncludedServices: { uuids, service in
            self.handle {
                if let uuids {
                    if let services = self.includedServices?[service] {
                        let discovered = services.filter({ uuids.contains($0.uuid) })
                        self.discoveredIncludedServices[service] = (discovered + (self.discoveredIncludedServices[service] ?? [])).uniqued()
                    } else {
                        self.discoveredIncludedServices[service] = []
                    }
                } else {
                    self.discoveredIncludedServices[service] = self.includedServices?[service] ?? []
                }
                if let service = service as? CBMutableService {
                    service.includedServices = self.includedServices![service]
                }
                self.didDiscoverIncludedServicesSubject.send((service, nil))
            }
        },
        discoverCharacteristics: { uuids, service in
            self.handle {
                self.didDiscoverCharacteristicsSubject.send((service, nil))
            }
        },
        readValueForCharacteristic: { characteristic in
            self.handle {
                Task {
                    do {
                        guard let delegate = self.delegate else {
                            throw CBATTError(.requestNotSupported)
                        }
                        let data = try await delegate.mockPeripheralHandleReadValue(forCharacteristic: characteristic)
                        self.updateValue(forCharacteristic: characteristic, value: data)
                    } catch {
                        self.didUpdateValueForCharacteristicSubject.send((characteristic, error))
                    }
                }
            }
        },
        maximumWriteValueLength: { writeType in writeType == .withResponse ? self.maximumWriteWithResponseValueLength : self.maximumWriteWithoutResponseValueLength },
        writeValueForCharacteristic: { data, characteristic, writeType in
            self.handle {
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
            }
        },
        setNotifyValue: { enabled, characteristic in
            self.handle {
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
            }
        },
        discoverDescriptors: { characteristic in
            self.handle {
                self.didDiscoverDescriptorsSubject.send((characteristic, nil))
            }
        },
        readValueForDescriptor: { descriptor in
            self.handle {
                Task {
                    do {
                        guard let delegate = self.delegate else {
                            throw CBATTError(.requestNotSupported)
                        }
                        let data = try await delegate.mockPeripheralHandleReadValue(forDescriptor: descriptor)
                        self.updateValue(forDescriptor: descriptor, value: data)
                    } catch {
                        self.didUpdateValueForDescriptorSubject.send((descriptor, error))
                    }
                }
            }
        },
        writeValueForDescriptor: { data, descriptor in
            self.handle {
                Task {
                    do {
                        guard let delegate = self.delegate else {
                            throw CBATTError(.requestNotSupported)
                        }
                        try await delegate.mockPeripheralHandleWriteValue(forDescriptor: descriptor, value: data)
                        self.didWriteValueForDescriptorSubject.send((descriptor, nil))
                    } catch {
                        self.didWriteValueForDescriptorSubject.send((descriptor, error))
                    }
                }
            }
        },
        openL2CAPChannel: { psm in
            self.handle {
                if let error = self.openL2CAPChannelError {
                    self.didOpenL2CAPChannelSubject.send((nil, error))
                } else {
                    self.didOpenL2CAPChannelSubject.send((L2CAPChannel(peer: self.peripheral, inputStream: InputStream(), outputStream: OutputStream(), psm: psm), nil))
                }
            }
        },
        didReadRSSI: self.$rssi.map({ Result<Double, any Error>.success($0) }).eraseToAnyPublisher(),
        didDiscoverServices: self.didDiscoverServicesSubject.eraseToAnyPublisher(),
        didDiscoverIncludedServices: self.didDiscoverIncludedServicesSubject.eraseToAnyPublisher(),
        didDiscoverCharacteristics: self.didDiscoverCharacteristicsSubject.eraseToAnyPublisher(),
        didUpdateValueForCharacteristic: self.didUpdateValueForCharacteristicSubject.eraseToAnyPublisher(),
        didWriteValueForCharacteristic: self.didWriteValueForCharacteristicSubject.eraseToAnyPublisher(),
        didUpdateNotificationState: self.didUpdateNotificationStateSubject.eraseToAnyPublisher(),
        didDiscoverDescriptorsForCharacteristic: self.didDiscoverDescriptorsSubject.eraseToAnyPublisher(),
        didUpdateValueForDescriptor: self.didUpdateValueForDescriptorSubject.eraseToAnyPublisher(),
        didWriteValueForDescriptor: self.didWriteValueForDescriptorSubject.eraseToAnyPublisher(),
        didOpenChannel: self.didOpenL2CAPChannelSubject.eraseToAnyPublisher(),
        isReadyToSendWriteWithoutResponse: self.$canSendWriteWithoutResponse.filter({ $0 }).map({ _ in Void() }).eraseToAnyPublisher(),
        nameUpdates: self.$name.eraseToAnyPublisher(),
        invalidatedServiceUpdates: self.invalidatedServicesSubject.eraseToAnyPublisher()
        )
    }
    
    public func updateValue(forCharacteristic characteristic: CBCharacteristic, value: Data) {
        (characteristic as? CBMutableCharacteristic)?.value = value
        didUpdateValueForCharacteristicSubject.send((characteristic, nil))
    }
    
    public func updateValue(forDescriptor descriptor: CBDescriptor, value: Data) {
        // Users can't set the value on a `CBMutableDescriptor` descriptor, so we can only implement this correctly with a subclass `MockDescriptor` if the user has created the descriptor with that class
        (descriptor as? MockDescriptor)?.value = value
        didUpdateValueForDescriptorSubject.send((descriptor, nil))
    }
}

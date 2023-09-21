//
//  MockCentralManager.swift
//  CombineCoreBluetooth
//
//  Created by Nick Brook on 05/09/2023.
//

import Foundation
import CoreBluetooth
import Combine

protocol MockCentralDelegate: AnyObject {
    func mockCentralManagerAuthorizationRequest(centralManager: MockCentralManager) async -> CBManagerAuthorization
    func mockCentralManagerNotAuthorized(centralManager: MockCentralManager) -> Void
}

private class MockCentralDelegateDefaultImplementation: MockCentralDelegate {
    func mockCentralManagerAuthorizationRequest(centralManager: MockCentralManager) async -> CBManagerAuthorization {
        return .allowedAlways
    }
    func mockCentralManagerNotAuthorized(centralManager: MockCentralManager) {
        
    }
    static let `default` = MockCentralDelegateDefaultImplementation()
}

public class MockCentralManager {
    weak var delegate: MockCentralDelegate? = MockCentralDelegateDefaultImplementation.default
    
    private(set) public var centralManager: CentralManager!
    
    @Published public var state: CBManagerState = .unknown
    public var authorization: CBManagerAuthorization = .notDetermined
    private var scanningForServices: [CBUUID]? = nil
    private var scanningOptions: CentralManager.ScanOptions? = nil
    func shouldSendAdvertisement(peripheral: MockPeripheral) -> Bool {
        guard isScanning, peripheral.discoverable else { return false }
        guard scanningOptions?.allowDuplicates ?? false || discoveredPeripherals[peripheral.peripheral.identifier] == nil else {
            return false
        }
        guard let scanningForServices else { return true }
        return !Set(scanningForServices).intersection(Set(peripheral.peripheral.services?.map({ $0.uuid }) ?? [])).isEmpty
    }
    @Published public private(set) var isScanning = false
    
    private(set) var addedPeripherals: [UUID: MockPeripheral] = [:]
    private(set) var discoveredPeripherals: [UUID: Peripheral] = [:]
    private(set) var knownPeripherals: [UUID: Peripheral] = [:]
    private(set) var connectedPeripherals: [UUID: Peripheral] = [:]
    
    private(set) var registeredConnectionEvents: [CBConnectionEventMatchingOption: Any] = [:]
    
    private let willRestoreStateSubject: any Subject<[String: Any], Never> = PassthroughSubject()
    private let didConnectPeripheralSubject: any Subject<Peripheral, Never> = PassthroughSubject()
    private let didFailToConnectPeripheralSubject: any Subject<(Peripheral, Error?), Never> = PassthroughSubject()
    private let didDisconnectPeripheralSubject: any Subject<(Peripheral, Error?), Never> = PassthroughSubject()
    private let connectionEventDidOccurSubject: any Subject<(CBConnectionEvent, Peripheral), Never> = PassthroughSubject()
    private let didDiscoverPeripheralSubject: any Subject<PeripheralDiscovery, Never> = PassthroughSubject()
    private let didUpdateACNSAuthorizationForPeripheralSubject: any Subject<Peripheral, Never> = PassthroughSubject()
    
    private var advertiserCancellables: Set<AnyCancellable> = []
    
    public func addPeripherals(peripherals: [MockPeripheral], addAsRestorable: Bool = true) {
        peripherals.forEach({ addPeripheral(peripheral:$0, addAsRestorable: addAsRestorable) })
    }
    
    public func addPeripheral(peripheral: MockPeripheral, addAsRestorable: Bool = true) {
        self.addedPeripherals[peripheral.peripheral.identifier] = peripheral
        if addAsRestorable {
            self.knownPeripherals[peripheral.peripheral.identifier] = peripheral.peripheral
        }
        peripheral
            .$advertiser
            .flatMap({ $0 })
            .filter({ _ in self.shouldSendAdvertisement(peripheral: peripheral) })
            .map({ params in
                self.discoveredPeripherals[peripheral.peripheral.identifier] = peripheral.peripheral
                return PeripheralDiscovery(peripheral: peripheral.peripheral, advertisementData: params.advertisementData, rssi: params.rssi)
            })
            .subscribe(self.didDiscoverPeripheralSubject)
            .store(in: &advertiserCancellables)
        
    }
    
    private func shouldProcessConnectionEvent(connectionEvent: CBConnectionEvent, peripheral: Peripheral) -> Bool {
#if !os(macOS)
        if let services = registeredConnectionEvents[.serviceUUIDs] as? [CBUUID], let peripheralServices = peripheral.services?.map({ $0.uuid }), !Set(services).intersection(peripheralServices).isEmpty {
            return true
        }
        if let identifiers = registeredConnectionEvents[.peripheralUUIDs] as? [UUID], identifiers.contains(peripheral.identifier) {
            return true
        }
#endif
        return false
    }
    
    private func processConnectionEvent(connectionEvent: CBConnectionEvent, peripheral: Peripheral) {
        if shouldProcessConnectionEvent(connectionEvent: connectionEvent, peripheral: peripheral) {
            connectionEventDidOccurSubject.send((connectionEvent, peripheral))
        }
    }
    
    public init() {
        centralManager = .unimplemented(
            state: { self.state },
            authorization: { self.authorization },
            isScanning: { self.isScanning },
            supportsFeatures: { _ in true },
            retrievePeripheralsWithIdentifiers: { uuids in Array(self.knownPeripherals.filter({ uuids.contains($0.key) }).values) },
            retrieveConnectedPeripheralsWithServices: { uuids in
                let uuids = Set(uuids)
                return Array(self.connectedPeripherals.filter({
                    guard let services = $0.value.services else { return false }
                    return uuids.intersection(Set(services).map({ $0.uuid })).count > 0
                }).values)
            },
            scanForPeripheralsWithServices: { uuids, options in
                switch self.authorization {
                case .notDetermined:
                    Task {
                        guard let result = await self.delegate?.mockCentralManagerAuthorizationRequest(centralManager: self) else {
                            return
                        }
                        self.authorization = result
                        if result == .allowedAlways {
                            self.scanningForServices = uuids
                            self.scanningOptions = options
                            self.isScanning = true
                        }
                    }
                case .allowedAlways:
                    self.scanningForServices = uuids
                    self.scanningOptions = options
                    self.isScanning = true
                default:
                    self.delegate?.mockCentralManagerNotAuthorized(centralManager: self)
                }
            },
            stopScanForPeripherals: { self.isScanning = false },
            connectToPeripheral: { peripheral, options in
                guard let mock = self.addedPeripherals[peripheral.identifier], self.knownPeripherals[peripheral.identifier] != nil else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.didFailToConnectPeripheralSubject.send((peripheral, CBError(CBError.unknownDevice)))
                    }
                    return
                }
                guard mock.connectable else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.didFailToConnectPeripheralSubject.send((peripheral, CBError(CBError.connectionFailed)))
                    }
                    return
                }
                guard self.connectedPeripherals[peripheral.identifier] == nil else { return }
                mock.state = .connecting
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                    guard mock.state == .connecting else { return }
                    mock.state = .connected
                    self.connectedPeripherals[peripheral.identifier] = peripheral
                    self.didConnectPeripheralSubject.send(peripheral)
                    self.processConnectionEvent(connectionEvent: .peerConnected, peripheral: peripheral)
                })
            },
            cancelPeripheralConnection: { peripheral in
                guard let mock = self.addedPeripherals[peripheral.identifier] else { return }
                guard mock.state == .connected || mock.state == .connecting else { return }
                mock.state = .disconnecting
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                    guard mock.state == .disconnecting else { return }
                    mock.state = .disconnected
                    self.connectedPeripherals.removeValue(forKey: peripheral.identifier)
                    self.didDisconnectPeripheralSubject.send((peripheral, nil))
                    self.processConnectionEvent(connectionEvent: .peerDisconnected, peripheral: peripheral)
                })
            },
            registerForConnectionEvents: { connectionEvents in
                guard let connectionEvents else {
                    self.registeredConnectionEvents = [:]
                    return
                }
                self.registeredConnectionEvents.merge(connectionEvents) { _, new in new }
            },
            didUpdateState: $state.eraseToAnyPublisher(),
            willRestoreState: willRestoreStateSubject.eraseToAnyPublisher(),
            didConnectPeripheral: didConnectPeripheralSubject.eraseToAnyPublisher(),
            didFailToConnectPeripheral: didFailToConnectPeripheralSubject.eraseToAnyPublisher(),
            didDisconnectPeripheral: didDisconnectPeripheralSubject.eraseToAnyPublisher(),
            connectionEventDidOccur: connectionEventDidOccurSubject.eraseToAnyPublisher(),
            didDiscoverPeripheral: didDiscoverPeripheralSubject.eraseToAnyPublisher(),
            didUpdateACNSAuthorizationForPeripheral: didUpdateACNSAuthorizationForPeripheralSubject.eraseToAnyPublisher()
        )
    }
}

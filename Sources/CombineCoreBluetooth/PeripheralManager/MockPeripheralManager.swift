//
//  File.swift
//  
//
//  Created by Nick Brook on 27/09/2023.
//

import Foundation
import CoreBluetooth


/// A delegate protocol for the `MockPeripheralManager`
public protocol MockPeripheralManagerDelegate: AnyObject {
    
    /// Handle a characteristic value update
    /// - Parameters:
    ///   - peripheralManager: The peripheral manager
    ///   - value: The new value
    ///   - characteristic: The characteristic
    ///   - centrals: The centrals the update should be sent to
    /// - Returns: `true` if the update was successful, `false` otherwise
    func mockPeripheralManager(peripheralManager: MockPeripheralManager, didUpdateValue value: Data, forCharacteristic characteristic: CBCharacteristic, onCentrals centrals: [Central]?) -> Bool
}


/// A mock peripheral manager to make implementing mocks easier
public class MockPeripheralManager {
    
    /// The (unimplemented) peripheral manager
    private(set) public var peripheralManager: PeripheralManager!
    
    /// The delegate used to handle any calls which require a dynamic response
    weak var delegate: MockPeripheralManagerDelegate?
    
    // User parameters used to respond to requests

    /// The delay in handling requests
    public var handlingDelay: TimeInterval = 1
    /// The state of the peripheral manager
    @Published public var state: CBManagerState = .unknown {
        didSet {
            guard state != oldValue else { return }
            self.isAdvertising = false
            self.advertisementData = nil
            self.latencies.removeAll()
            self.services.removeAll()
            self.L2CAPChannels.removeAll()
            for (_, continuation) in self.pendingReadRequests {
                continuation.resume(throwing: CBError(.peripheralDisconnected))
            }
            self.pendingReadRequests.removeAll()
            for (_, requests) in self.pendingWriteRequests {
                requests.continuation.resume(throwing: CBError(.peripheralDisconnected))
            }
            self.pendingWriteRequests.removeAll()
            self.subscribedCharacteristics.removeAll()
        }
    }
    /// The authorization state of the peripheral manager
    @Published public var authorization: CBManagerAuthorization = .notDetermined
    /// The error to return when advertising is started. If `nil`, advertising will start successfully. Default `nil`
    public var startAdvertisingError: Error?
    /// The error to return when a service is added. If `nil`, services will be added successfully. Default `nil`
    public var didAddServiceError: Error?
    /// The error to return when publishing an L2CAP channel. If `nil`, channels will be published successfully. Default `nil`
    public var publishL2CAPChannelError: Error?
    /// The error to return when unpublishing an L2CAP channel. If `nil`, channels will be unpublished successfully. Default `nil`
    public var unpublishL2CAPChannelError: Error?
    
    // Properties updated from requests to the mock
    
    /// Indicates if the peripheral is advertising or not
    @Published public var isAdvertising = false
    /// The data the peripheral is advertising
    public var advertisementData: AdvertisementData?
    /// The latencies of centrals set to the peripheral manager
    @Published public var latencies: [Central: CBPeripheralManagerConnectionLatency] = [:]
    /// Services that have been added to the peripheral manager
    @Published public private(set) var services: [CBService] = []
    /// The next PSM that will be used
    private var nextPSM: CBL2CAPPSM = 0
    /// The currently published L2CAP channels. A map of PSM > encrypted (bool)
    @Published public private(set) var L2CAPChannels: [CBL2CAPPSM: Bool] = [:]
    /// Pending read requests on the peripheral
    @Published public private(set) var pendingReadRequests: [ATTRequest: CheckedContinuation<CBATTError.Code, Error>] = [:]
    public class PendingWriteRequest {
        let identifier = UUID()
        let requests: [ATTRequest]
        var responses: [ATTRequest: CBATTError.Code] = [:]
        let continuation: CheckedContinuation<[ATTRequest: CBATTError.Code], Error>
        init(requests: [ATTRequest], continuation: CheckedContinuation<[ATTRequest : CBATTError.Code], Error>) {
            self.requests = requests
            self.continuation = continuation
        }
    }
    /// pending write requests on the peripheral
    @Published public private(set) var pendingWriteRequests: [UUID: PendingWriteRequest] = [:]
    /// The subscribed centrals
    @Published public private(set) var subscribedCharacteristics: [Central: Set<CBCharacteristic>] = [:]
    
    // subjects
    private let didStartAdvertisingSubject: any Subject<Error?, Never> = PassthroughSubject()
    private let didAddServiceSubject: any Subject<(CBService, Error?), Never> = PassthroughSubject()
    private let centralDidSubscribeToCharacteristicSubject: any Subject<(Central, CBCharacteristic), Never> = PassthroughSubject()
    private let centralDidUnsubscribeToCharacteristicSubject: any Subject<(Central, CBCharacteristic), Never> = PassthroughSubject()
    private let didReceiveReadRequestSubject: any Subject<ATTRequest, Never> = PassthroughSubject()
    private let didReceiveWriteRequestsSubject: any Subject<[ATTRequest], Never> = PassthroughSubject()
    private let readyToUpdateSubscribersSubject: any Subject<Void, Never> = PassthroughSubject()
    private let didPublishL2CAPChannelSubject: any Subject<(CBL2CAPPSM, Error?), Never> = PassthroughSubject()
    private let didUnpublishL2CAPChannelSubject: any Subject<(CBL2CAPPSM, Error?), Never> = PassthroughSubject()
    private let didOpenL2CAPChannelSubject: any Subject<(L2CAPChannel?, Error?), Never> = PassthroughSubject()
    
    let asyncQueue = DispatchQueue.global(qos: .utility)
    
    /// Perform a handler after a delay
    /// - Parameter handler: The handler to perform
    private func handle(_ handler: @escaping () -> Void) {
        asyncQueue.asyncAfter(deadline: .now() + self.handlingDelay, execute: handler)
    }
    
    /// Check the state of the peripheral manager before performing any actions
    private func checkState() {
        assert(state == .poweredOn && authorization == .allowedAlways)
    }
    
    init() {
        peripheralManager = PeripheralManager.unimplemented(
            state: { self.state },
            authorization: { self.authorization },
            isAdvertising: { self.isAdvertising },
            startAdvertising: { advData in
                self.checkState()
                self.handle {
                    if let startAdvertisingError = self.startAdvertisingError {
                        self.advertisementData = nil
                        if self.isAdvertising {
                            self.isAdvertising = false
                        }
                        self.didStartAdvertisingSubject.send(startAdvertisingError)
                    } else {
                        self.advertisementData = advData
                        self.isAdvertising = true
                        self.didStartAdvertisingSubject.send(nil)
                    }
                }
            },
            stopAdvertising: {
                guard self.isAdvertising else { return }
                self.handle {
                    self.advertisementData = nil
                    self.isAdvertising = false
                }
            },
            setDesiredConnectionLatency: { latency, central in
                self.checkState()
                self.latencies[central] = latency
            },
            add: { service in
                self.checkState()
                self.handle {
                    if let didAddServiceError = self.didAddServiceError {
                        self.didAddServiceSubject.send((service, didAddServiceError))
                    } else {
                        self.services.append(service)
                        self.didAddServiceSubject.send((service, nil))
                    }
                }
            },
            remove: { service in
                self.checkState()
                DispatchQueue.main.async {
                    self.services.removeAll(where: { $0 == service })
                }
            },
            removeAllServices: {
                self.checkState()
                DispatchQueue.main.async {
                    self.services.removeAll()
                }
            },
            respondToRequest: { request, errCode in
                self.checkState()
                if let cont = self.pendingReadRequests[request] {
                    self.pendingReadRequests[request] = nil
                    cont.resume(returning: errCode)
                }
                var requests: PendingWriteRequest? = nil
                for (_, reqs) in self.pendingWriteRequests {
                    if reqs.requests.contains(request) {
                        requests = reqs
                        break
                    }
                }
                if let requests {
                    requests.responses[request] = errCode
                    if requests.responses.count == requests.requests.count {
                        self.pendingWriteRequests[requests.identifier] = nil
                        requests.continuation.resume(returning: requests.responses)
                    }
                }
            },
            updateValueForCharacteristic: { data, characteristic, centrals in
                self.checkState()
                return self.delegate?.mockPeripheralManager(peripheralManager: self, didUpdateValue: data, forCharacteristic: characteristic, onCentrals: centrals) ?? true
            },
            publishL2CAPChannel: { withEncryption in
                self.checkState()
                self.handle {
                    let psm = self.nextPSM
                    self.nextPSM += 1
                    if let publishL2CAPChannelError = self.publishL2CAPChannelError {
                        self.didPublishL2CAPChannelSubject.send((psm, publishL2CAPChannelError))
                    } else {
                        self.L2CAPChannels[psm] = withEncryption
                        self.didPublishL2CAPChannelSubject.send((psm, nil))
                    }
                }
            },
            unpublishL2CAPChannel: { psm in
                self.checkState()
                self.handle {
                    if let unpublishL2CAPChannelError = self.unpublishL2CAPChannelError {
                        self.didUnpublishL2CAPChannelSubject.send((psm, unpublishL2CAPChannelError))
                    } else {
                        self.L2CAPChannels[psm] = nil
                        self.didUnpublishL2CAPChannelSubject.send((psm, nil))
                    }
                }
            },
            didUpdateState: $state.eraseToAnyPublisher(),
            didStartAdvertising: didStartAdvertisingSubject.eraseToAnyPublisher(),
            didAddService: didAddServiceSubject.eraseToAnyPublisher(),
            centralDidSubscribeToCharacteristic: centralDidSubscribeToCharacteristicSubject.eraseToAnyPublisher(),
            centralDidUnsubscribeToCharacteristic: centralDidUnsubscribeToCharacteristicSubject.eraseToAnyPublisher(),
            didReceiveReadRequest: didReceiveReadRequestSubject.eraseToAnyPublisher(),
            didReceiveWriteRequests: didReceiveWriteRequestsSubject.eraseToAnyPublisher(),
            readyToUpdateSubscribers: readyToUpdateSubscribersSubject.eraseToAnyPublisher(),
            didPublishL2CAPChannel: didPublishL2CAPChannelSubject.eraseToAnyPublisher(),
            didUnpublishL2CAPChannel: didUnpublishL2CAPChannelSubject.eraseToAnyPublisher(),
            didOpenL2CAPChannel: didOpenL2CAPChannelSubject.eraseToAnyPublisher())
    }
    
    /// Subscribe or unsubscribe to characteristics on the peripheral manager
    /// - Parameters:
    ///   - central: The central that is subscribing/unsubscribing
    ///   - subscribed: indicate if the central subscribed or unsubscribed
    ///   - characteristic: The characteristic the central subscribed/unsubscribed to
    public func central(_ central: Central, subscribed: Bool, toCharacteristic characteristic: CBCharacteristic) {
        self.checkState()
        if subscribed {
            if subscribedCharacteristics[central]?.contains(characteristic) ?? false {
                if subscribedCharacteristics[central] == nil {
                    subscribedCharacteristics[central] = []
                }
                subscribedCharacteristics[central]!.insert(characteristic)
                centralDidSubscribeToCharacteristicSubject.send((central, characteristic))
            }
        } else {
            if subscribedCharacteristics[central]?.contains(characteristic) ?? false {
                subscribedCharacteristics[central]!.remove(characteristic)
                centralDidUnsubscribeToCharacteristicSubject.send((central, characteristic))
            }
        }
    }
    
    /// Open an L2CAP channel that has been published
    /// - Parameters:
    ///   - peer: The peer that opened the channel
    ///   - inputStream: The input stream
    ///   - outputStream: The output stream
    ///   - psm: The PSM of the channel that has opened
    public func openL2CAPChannel(peer: Peer, inputStream: InputStream, outputStream: OutputStream, psm: CBL2CAPPSM) {
        self.checkState()
        if L2CAPChannels[psm] == nil { return }
        let channel = L2CAPChannel(peer: peer, inputStream: inputStream, outputStream: outputStream, psm: psm)
        didOpenL2CAPChannelSubject.send((channel, nil))
    }
    
    /// Trigger an error opening an L2CAP channel
    /// - Parameter error: The error that occurred opening the channel
    public func openL2CAPChannel(error: Error) {
        self.checkState()
        didOpenL2CAPChannelSubject.send((nil, error))
    }
    
    /// Perform a read request on the peripheral
    /// - Parameter request: The request
    /// - Returns: The result of the request
    /// - Throws: A `CBError` with code `CBError.connectionTimeout` if the request wasn't responded to within 30s
    public func performReadRequest(request: ATTRequest) async throws -> CBATTError.Code {
        self.checkState()
        return try await withCheckedThrowingContinuation { continuation in
            pendingReadRequests[request] = continuation
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                if self.pendingReadRequests[request] != nil {
                    self.pendingReadRequests[request] = nil
                    continuation.resume(throwing: CBError(CBError.connectionTimeout, userInfo: [:]))
                }
            }
        }
    }
    
    /// Perform write requests on the peripheral
    /// - Parameter requests: The requests
    /// - Returns: A map of requests to the results of the requests
    /// - Throws: A `CBError` with code `CBError.connectionTimeout` if the requests weren't all responded to within 30s
    public func performWriteRequests(requests: [ATTRequest]) async throws -> [ATTRequest: CBATTError.Code] {
        self.checkState()
        return try await withCheckedThrowingContinuation { continuation in
            let pending = PendingWriteRequest(requests: requests, continuation: continuation)
            pendingWriteRequests[pending.identifier] = pending
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                if self.pendingWriteRequests[pending.identifier] != nil {
                    self.pendingWriteRequests[pending.identifier] = nil
                    continuation.resume(throwing: CBError(CBError.connectionTimeout, userInfo: [:]))
                }
            }
        }
    }
}

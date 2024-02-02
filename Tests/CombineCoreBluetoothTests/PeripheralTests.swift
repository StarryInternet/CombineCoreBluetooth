//
//  PeripheralTests.swift
//  
//
//  Created by Kevin Lundberg on 4/26/22.
//

@testable import CombineCoreBluetooth
@preconcurrency import Combine
import XCTest
import ConcurrencyExtras

#if os(macOS) || os(iOS)
class PeripheralTests: XCTestCase {

  override func setUpWithError() throws {
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }

  override func tearDownWithError() throws {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }

  // MARK: - Services

  func testDiscoverServicesFindsExpectedServices() throws {
    let expectedServices = [
      CBMutableService(type: CBUUID(string: "0001"), primary: true)
    ]
    let otherServices = [
      CBMutableService(type: CBUUID(string: "0002"), primary: true)
    ]

    let p = Peripheral.failing(
      discoverServices: { _ in },
      didDiscoverServices: [
        (otherServices, nil),
        (expectedServices, nil)
      ].publisher.neverComplete()
    )

    let outputs = try p.discoverServices([CBUUID(string: "0001")]).waitForCompletion()
    XCTAssertEqual(outputs, [expectedServices])
  }

  func testDiscoverAMissingServiceDoesntComplete() throws {
    let expectedServiceIDs = [
      CBUUID(string: "0001"),
      CBUUID(string: "0002"),
    ]

    let actualServices = [
      CBMutableService(type: CBUUID(string: "0001"), primary: true),
      CBMutableService(type: CBUUID(string: "0003"), primary: true)
    ]

    let p = Peripheral.failing(
      discoverServices: { ids in },
      didDiscoverServices: Just((actualServices, nil)).append(Empty(completeImmediately: false)).eraseToAnyPublisher()
    )

    let outputs = try p.discoverServices(expectedServiceIDs).waitForCompletion(inverted: true)
    // data should never be obtained if not all services are discovered.
    XCTAssertEqual(outputs, nil)
  }

  func testDiscoverServicesOnlyYieldsFirstMatchingDiscoveredServiceEntry() throws {
    let expectedServices = [
      CBMutableService(type: CBUUID(string: "0123"), primary: true)
    ]

    let p = Peripheral.failing(
      discoverServices: { _ in },
      didDiscoverServices: [
        (expectedServices, nil),
        (expectedServices, nil)
      ].publisher.neverComplete()
    )

    let outputs = try p.discoverServices([CBUUID(string: "0123")]).waitForCompletion()
    XCTAssertEqual(outputs, [expectedServices])
  }

  func testDiscoverServicesWithNilIdsAlwaysSucceeds() throws {
    let services = [CBMutableService(type: CBUUID(string: "0001"), primary: true)]
    let otherServices = [CBMutableService(type: CBUUID(string: "0002"), primary: false)]

    let p = Peripheral.failing(
      discoverServices: { _ in },
      didDiscoverServices: [
        (services, nil),
      ].publisher.neverComplete()
    )

    let outputs = try p.discoverServices(nil).waitForCompletion()
    XCTAssertEqual(outputs, [services])

    let p2 = Peripheral.failing(
      discoverServices: { _ in },
      didDiscoverServices: [
        (otherServices, nil)
      ].publisher.neverComplete()
    )

    let outputs2 = try p2.discoverServices(nil).waitForCompletion()
    XCTAssertEqual(outputs2, [otherServices])
  }

  // MARK: - Included services

  func testDiscoverIncludedServicesFindsExpectedServices() throws {
    let service = CBMutableService(type: CBUUID(string: "0001"), primary: true)
    service.includedServices = [
      CBMutableService(type: CBUUID(string: "0011"), primary: false)
    ]
    let otherService = CBMutableService(type: CBUUID(string: "0002"), primary: false)

    let p = Peripheral.failing(
      discoverIncludedServices: { _,_  in },
      didDiscoverIncludedServices: [
        (otherService, nil),
        (service, nil)
      ].publisher.neverComplete()
    )

    let outputs = try p.discoverIncludedServices([CBUUID(string: "0011")], for: service).waitForCompletion()
    XCTAssertEqual(outputs, [service.includedServices])
  }

  func testDiscoverMissingIncludedServicesDoesntComplete() throws {
    let service = CBMutableService(type: CBUUID(string: "0001"), primary: true)

    let p = Peripheral.failing(
      discoverIncludedServices: { _,_  in },
      didDiscoverIncludedServices: Just((service, nil)).neverComplete()
    )

    let outputs = try p.discoverIncludedServices([CBUUID(string: "0011")], for: service).waitForCompletion(inverted: true)
    // data should never be obtained if not all services are discovered.
    XCTAssertEqual(outputs, nil)
  }

  func testDiscoverIncludedServicesOnlyYieldsFirstMatchingDiscoveredServiceEntry() throws {
    let service = CBMutableService(type: CBUUID(string: "0001"), primary: true)
    service.includedServices = [CBMutableService(type: CBUUID(string: "0011"), primary: false)]

    let p = Peripheral.failing(
      discoverIncludedServices: { _,_  in },
      didDiscoverIncludedServices: [
        (service, nil),
        (service, nil)
      ].publisher.neverComplete()
    )

    let outputs = try p.discoverIncludedServices([CBUUID(string: "0011")], for: service).waitForCompletion()

    XCTAssertEqual(outputs, [service.includedServices])
  }

  func testDiscoverIncludedServicesWithNilIdsAlwaysSucceeds() throws {
    let service = CBMutableService(type: CBUUID(string: "0001"), primary: true)
    service.includedServices = [CBMutableService(type: CBUUID(string: "0011"), primary: false)]

    let p = Peripheral.failing(
      discoverIncludedServices: { _,_  in },
      didDiscoverIncludedServices: [
        (service, nil),
      ].publisher.neverComplete()
    )

    let outputs = try p.discoverIncludedServices(nil, for: service).waitForCompletion()
    XCTAssertEqual(outputs, [service.includedServices])

    let p2 = Peripheral.failing(
      discoverIncludedServices: { _,_ in },
      didDiscoverIncludedServices: [
        (service.includedServices!.first!, nil)
      ].publisher.neverComplete()
    )

    let outputs2 = try p2.discoverIncludedServices(nil, for: service.includedServices!.first!).waitForCompletion()
    XCTAssertEqual(outputs2, [nil])
  }
  
  // MARK: - Characteristics
  
  func testSubscribeToCharacteristicWorks() {
    let c = CBMutableCharacteristic(type: .init(string: "0001"), properties: [.read, .notify], value: nil, permissions: [.readEncryptionRequired])
    
    let subject = PassthroughSubject<(Data?, Error?), Never>()
    let notifyValues: LockIsolated<[Bool]> = LockIsolated([])
    
    let p = Peripheral.failing(
      setNotifyValue: { notifyValue, characteristic in notifyValues.withValue { $0.append(notifyValue) } },
      didUpdateValueForCharacteristic: subject
        .map {
          c.value = $0
          return (c, $1)
        }
        .eraseToAnyPublisher(),
      didUpdateNotificationState: Just((c, nil)).eraseToAnyPublisher()
    )
    
    var values: [Data?] = []
    let cancellable = p.subscribeToUpdates(on: c).sink { cancellable in
      if case let .failure(error) = cancellable {
        XCTFail("\(error)")
      }
    } receiveValue: {
      values.append($0)
    }
    XCTAssertEqual(notifyValues.withValue { $0 }, [true])
    
    subject.send((Data("a".utf8), nil))
    subject.send((Data("b".utf8), nil))
    cancellable.cancel()
    // test that cancellation unsubscribes to the characteristic
    XCTAssertEqual(notifyValues.withValue { $0 }, [true, false])
    
    XCTAssertEqual(values, [Data("a".utf8), Data("b".utf8)])
  }
  
  func testSubscribeToCharacteristicFailsWhenSetNotifyValueFails() {
    let c = CBMutableCharacteristic(type: .init(string: "0001"), properties: [.read, .notify], value: nil, permissions: [.readEncryptionRequired])
    
    let notifyValues: LockIsolated<[Bool]> = LockIsolated([])
    
    struct SomeError: Error {}
    
    let p = Peripheral.failing(
      setNotifyValue: { notifyValue, characteristic in notifyValues.withValue { $0.append(notifyValue) } },
      didUpdateValueForCharacteristic: Empty().eraseToAnyPublisher(),
      didUpdateNotificationState: Just((c, SomeError())).eraseToAnyPublisher()
    )
    
    var values: [Data?] = []
    let cancellable = p.subscribeToUpdates(on: c).sink { cancellable in
      if case .finished = cancellable {
        XCTFail("Expected a failure")
      }
    } receiveValue: {
      values.append($0)
    }
    XCTAssertEqual(notifyValues.withValue { $0 }, [true])
    XCTAssertEqual(values, [])
    cancellable.cancel()
  }
}

// MARK: -

extension Publisher {
  func waitForCompletion(inverted: Bool = false) throws -> [Output]? {
    let exp = XCTestExpectation(description: "foo")
    exp.isInverted = inverted
    var error: Failure?
    var value: [Output]?
    let sub = collect().sink { completion in
      if case let .failure(e) = completion {
        error = e
      }
      exp.fulfill()
    } receiveValue: { output in
      value = output
    }

    _ = XCTWaiter.wait(for: [exp], timeout: 1)
    sub.cancel()

    if let error = error {
      throw error
    } else {
      return value
    }
  }

  func firstValue() async throws -> Output? {
    try await values.first(where: { _ in true })
  }

  func neverComplete() -> AnyPublisher<Output, Failure> {
    append(Empty(completeImmediately: false))
      .eraseToAnyPublisher()
    }

  private var values: AsyncThrowingStream<Output, Error> {
    AsyncThrowingStream { continuation in
      let cancellable: AnyCancellable = sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            continuation.finish()
          case .failure(let error):
            continuation.finish(throwing: error)
          }
        }, receiveValue: { value in
          continuation.yield(value)
        }
      )
      continuation.onTermination = { @Sendable _ in
        cancellable.cancel()
      }
    }
  }
}

extension Peripheral {

  static func fail(_ name: String, file: StaticString = #file, line: UInt = #line) -> Void {
    XCTFail("\(name) called when no implementation is provided", file: file, line: line)
  }

  @_disfavoredOverload
  static func fail(_ name: String, file: StaticString = #file, line: UInt = #line) -> @Sendable () -> Void {
    { fail(name, file: file, line: line) }
  }

  static func fail<A>(_ name: String, file: StaticString = #file, line: UInt = #line) -> @Sendable (A) -> Void {
    { _ in fail(name, file: file, line: line) }
  }

  static func fail<A,B>(_ name: String, file: StaticString = #file, line: UInt = #line) -> @Sendable (A,B) -> Void {
    { _, _ in fail(name, file: file, line: line) }
  }

  static func fail<A,B,C>(_ name: String, file: StaticString = #file, line: UInt = #line) -> @Sendable (A,B,C) -> Void {
    { _, _, _ in fail(name, file: file, line: line) }
  }

  static func fail<Output, Failure: Error>(_ name: String, file: StaticString = #file, line: UInt = #line) -> AnyPublisher<Output, Failure> {
    Empty()
      .handleEvents(
        receiveSubscription: { _ in XCTFail("\(name) subscribed to when no implementation is provided", file: file, line: line) }
      )
      .eraseToAnyPublisher()
  }

  static func failing(
    name: String? = nil,
    identifier: UUID = .init(),
    state: @escaping @Sendable () -> CBPeripheralState = { fail("name"); return .disconnected },
    services: @escaping @Sendable () -> [CBService]? = { fail("services"); return nil },
    canSendWriteWithoutResponse: @escaping @Sendable () -> Bool = { fail("canSendWriteWithoutResponse"); return false },
    ancsAuthorized: @escaping @Sendable () -> Bool = { fail("ancsAuthorized"); return false },
    readRSSI: @escaping @Sendable () -> Void = fail("readRSSI"),
    discoverServices: @escaping @Sendable ([CBUUID]?) -> Void = fail("discoverServices"),
    discoverIncludedServices: @escaping @Sendable ([CBUUID]?, CBService) -> Void = fail("discoverIncludedServices"),
    discoverCharacteristics: @escaping @Sendable ([CBUUID]?, CBService) -> Void = fail("discoverCharacteristics"),
    readValueForCharacteristic: @escaping @Sendable (CBCharacteristic) -> Void = fail("readValueForCharacteristic"),
    maximumWriteValueLength: @escaping @Sendable (CBCharacteristicWriteType) -> Int = { _ in fail("maximumWriteValueLength"); return 0 },
    writeValueForCharacteristic: @escaping @Sendable (Data, CBCharacteristic, CBCharacteristicWriteType) -> Void = fail("writeValueForCharacteristic"),
    setNotifyValue: @escaping @Sendable (Bool, CBCharacteristic) -> Void = fail("setNotifyValue"),
    discoverDescriptors: @escaping @Sendable (CBCharacteristic) -> Void = fail("discoverDescriptors"),
    readValueForDescriptor: @escaping @Sendable (CBDescriptor) -> Void = fail("readValueForDescriptor"),
    writeValueForDescriptor: @escaping @Sendable (Data, CBDescriptor) -> Void = fail("writeValueForDescriptor"),
    openL2CAPChannel: @escaping @Sendable (CBL2CAPPSM) -> Void = fail("openL2CAPChannel"),
    didReadRSSI:                             AnyPublisher<Result<Double, Error>, Never> = fail("didReadRSSI"),
    didDiscoverServices:                     AnyPublisher<([CBService], Error?), Never> = fail("didDiscoverServices"),
    didDiscoverIncludedServices:             AnyPublisher<(CBService, Error?), Never> = fail("didDiscoverIncludedServices"),
    didDiscoverCharacteristics:              AnyPublisher<(CBService, Error?), Never> = fail("didDiscoverCharacteristics"),
    didUpdateValueForCharacteristic:         AnyPublisher<(CBCharacteristic, Error?), Never> = fail("didUpdateValueForCharacteristic"),
    didWriteValueForCharacteristic:          AnyPublisher<(CBCharacteristic, Error?), Never> = fail("didWriteValueForCharacteristic"),
    didUpdateNotificationState:              AnyPublisher<(CBCharacteristic, Error?), Never> = fail("didUpdateNotificationState"),
    didDiscoverDescriptorsForCharacteristic: AnyPublisher<(CBCharacteristic, Error?), Never> = fail("didDiscoverDescriptorsForCharacteristic"),
    didUpdateValueForDescriptor:             AnyPublisher<(CBDescriptor, Error?), Never> = fail("didUpdateValueForDescriptor"),
    didWriteValueForDescriptor:              AnyPublisher<(CBDescriptor, Error?), Never> = fail("didWriteValueForDescriptor"),
    didOpenChannel:                          AnyPublisher<(L2CAPChannel?, Error?), Never> = fail("didOpenChannel"),
    isReadyToSendWriteWithoutResponse: AnyPublisher<Void, Never> = fail("isReadyToSendWriteWithoutResponse"),
    nameUpdates: AnyPublisher<String?, Never> = fail("nameUpdates"),
    invalidatedServiceUpdates: AnyPublisher<[CBService], Never> = fail("invalidatedServiceUpdates")
  ) -> Peripheral {
    Peripheral(
      rawValue: nil,
      delegate: nil,
      _name: { name },
      _identifier: { identifier },
      _state: state,
      _services: services,
      _canSendWriteWithoutResponse: canSendWriteWithoutResponse,
      _ancsAuthorized: ancsAuthorized,
      _readRSSI: readRSSI,
      _discoverServices: discoverServices,
      _discoverIncludedServices: discoverIncludedServices,
      _discoverCharacteristics: discoverCharacteristics,
      _readValueForCharacteristic: readValueForCharacteristic,
      _maximumWriteValueLength: maximumWriteValueLength,
      _writeValueForCharacteristic: writeValueForCharacteristic,
      _setNotifyValue: setNotifyValue,
      _discoverDescriptors: discoverDescriptors,
      _readValueForDescriptor: readValueForDescriptor,
      _writeValueForDescriptor: writeValueForDescriptor,
      _openL2CAPChannel: openL2CAPChannel,

      didReadRSSI: didReadRSSI,
      didDiscoverServices: didDiscoverServices,
      didDiscoverIncludedServices: didDiscoverIncludedServices,
      didDiscoverCharacteristics: didDiscoverCharacteristics,
      didUpdateValueForCharacteristic: didUpdateValueForCharacteristic,
      didWriteValueForCharacteristic: didWriteValueForCharacteristic,
      didUpdateNotificationState: didUpdateNotificationState,
      didDiscoverDescriptorsForCharacteristic: didDiscoverDescriptorsForCharacteristic,
      didUpdateValueForDescriptor: didUpdateValueForDescriptor,
      didWriteValueForDescriptor: didWriteValueForDescriptor,
      didOpenChannel: didOpenChannel,

      isReadyToSendWriteWithoutResponse: isReadyToSendWriteWithoutResponse,
      nameUpdates: nameUpdates,
      invalidatedServiceUpdates: invalidatedServiceUpdates
    )
  }
}
#endif

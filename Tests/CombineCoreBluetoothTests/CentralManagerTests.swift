import XCTest
@testable import CombineCoreBluetooth

final class CentralManagerTests: XCTestCase {
  var cancellables: Set<AnyCancellable>!

  override func setUpWithError() throws {
    cancellables = []
  }

  override func tearDownWithError() throws {
    cancellables = nil
  }

  func testMonitorConnectionSendsExpectedValues() {
    let didConnectPeripheral = PassthroughSubject<Peripheral, Never>()
    let didDisconnectPeripheral = PassthroughSubject<(Peripheral, Error?), Never>()
    let monitoredPeripheral = Peripheral.unimplemented(name: "monitored")
    let unmonitoredPeripheral = Peripheral.unimplemented(name: "unmonitored")

    let centralManager = CentralManager.unimplemented(
      didConnectPeripheral: didConnectPeripheral.eraseToAnyPublisher(),
      didDisconnectPeripheral: didDisconnectPeripheral.eraseToAnyPublisher()
    )

    var values: [Bool] = []
    centralManager.monitorConnection(for: monitoredPeripheral).sink {
      values.append($0)
    }.store(in: &cancellables)

    didConnectPeripheral.send(monitoredPeripheral)
    didDisconnectPeripheral.send((monitoredPeripheral, nil))
    didConnectPeripheral.send(monitoredPeripheral)

    XCTAssertEqual(values, [true, false, true])

    didConnectPeripheral.send(unmonitoredPeripheral)
    didDisconnectPeripheral.send((unmonitoredPeripheral, nil))
    didConnectPeripheral.send(unmonitoredPeripheral)

    XCTAssertEqual(values, [true, false, true], "monitorConnection returned values for a peripheral it wasn't monitoring")
  }

  func testMonitorConnectionDisconnectErrorsDontAffectResults() {
    let didConnectPeripheral = PassthroughSubject<Peripheral, Never>()
    let didDisconnectPeripheral = PassthroughSubject<(Peripheral, Error?), Never>()
    let monitoredPeripheral = Peripheral.unimplemented(name: "monitored")

    let centralManager = CentralManager.unimplemented(
      didConnectPeripheral: didConnectPeripheral.eraseToAnyPublisher(),
      didDisconnectPeripheral: didDisconnectPeripheral.eraseToAnyPublisher()
    )

    var values: [Bool] = []
    centralManager.monitorConnection(for: monitoredPeripheral).sink {
      values.append($0)
    }.store(in: &cancellables)

    struct SomeError: Error {}

    didDisconnectPeripheral.send((monitoredPeripheral, SomeError()))

    XCTAssertEqual(values, [false], "Errors from disconnects should not affect disconnect values sent to subscribers")
  }
  
  func testScanForPeripheralsScansOnlyOnSubscription() {
    var scanCount = 0
    var stopCount = 0
    let peripheralDiscovery = PassthroughSubject<PeripheralDiscovery, Never>()
    let centralManager = CentralManager.unimplemented(scanForPeripheralsWithServices: { _, _ in
      scanCount += 1
    }, stopScanForPeripherals: {
      stopCount += 1
    }, didDiscoverPeripheral: peripheralDiscovery.eraseToAnyPublisher()
    )
    
    let p = centralManager.scanForPeripherals(withServices: nil)
    XCTAssertEqual(scanCount, 0)
    let _ = p.sink(receiveValue: { _ in })
    XCTAssertEqual(scanCount, 1)
  }
  
  func testScanForPeripheralsStopsOnCancellation() {
    var scanCount = 0
    var stopCount = 0
    let peripheralDiscovery = PassthroughSubject<PeripheralDiscovery, Never>()
    let centralManager = CentralManager.unimplemented(scanForPeripheralsWithServices: { _, _ in
      scanCount += 1
    }, stopScanForPeripherals: {
      stopCount += 1
    }, didDiscoverPeripheral: peripheralDiscovery.eraseToAnyPublisher()
    )
    
    let p = centralManager.scanForPeripherals(withServices: nil)
    XCTAssertEqual(scanCount, 0)
    let cancellable = p.sink(receiveValue: { _ in })
    XCTAssertEqual(scanCount, 1)
    XCTAssertEqual(stopCount, 0)
    
    cancellable.cancel()
    XCTAssertEqual(scanCount, 1)
    XCTAssertEqual(stopCount, 1)
  }
}

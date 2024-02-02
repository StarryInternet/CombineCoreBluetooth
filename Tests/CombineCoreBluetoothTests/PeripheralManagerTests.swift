import XCTest
@testable import CombineCoreBluetooth
import ConcurrencyExtras

#if os(macOS) || os(iOS)
final class PeripheralManagerTests: XCTestCase {
  var cancellables: Set<AnyCancellable>!
  
  override func setUpWithError() throws {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    cancellables = []
  }
  
  override func tearDownWithError() throws {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    cancellables = nil
  }
  
  func testUpdateValueSuccessCase() throws {
    let characteristic = CBMutableCharacteristic(type: .init(string: "0001"), properties: [.notify], value: nil, permissions: [.readable])

    let central = Central.unimplemented(identifier: .init(), maximumUpdateValueLength: { 512 })
    let peripheralManager = PeripheralManager.unimplemented(
      updateValueForCharacteristic: { _, _, _ in true },
      readyToUpdateSubscribers: Just(()).eraseToAnyPublisher()
    )
    
    peripheralManager.updateValue(Data(), for: characteristic, onSubscribedCentrals: [central])
      .sink { c in
        if case let .failure(error) = c {
          XCTFail("Unexpected error: \(error)")
        }
      } receiveValue: { _ in
        
      }.store(in: &cancellables)
  }
  
  func testUpdateValueErrorCase() throws {
    let characteristic = CBMutableCharacteristic(type: .init(string: "0001"), properties: [.notify], value: nil, permissions: [.readable])
    let central = Central.unimplemented(identifier: .init(), maximumUpdateValueLength: { 512 })
    let readyToUpdateSubject = PassthroughSubject<Void, Never>()
    let peripheralManager = PeripheralManager.unimplemented(
      updateValueForCharacteristic: { _, _, _ in false },
      readyToUpdateSubscribers: readyToUpdateSubject.eraseToAnyPublisher()
    )
    
    var complete = false
    peripheralManager.updateValue(Data(), for: characteristic, onSubscribedCentrals: [central])
      .sink { c in
        complete = true
        if case .finished = c {
          XCTFail("Expected an error to be thrown if updating fails after the builtin retry count")
        }
      } receiveValue: { _ in
        
      }.store(in: &cancellables)
    
    for _ in 1...4 {
      readyToUpdateSubject.send(())
    }
    XCTAssert(complete)
  }
  
  
  func testUpdateValueSucceedsAfter4Retries() throws {
    let characteristic = CBMutableCharacteristic(type: .init(string: "0001"), properties: [.notify], value: nil, permissions: [.readable])
    let central = Central.unimplemented(identifier: .init(), maximumUpdateValueLength: { 512 })
    let readyToUpdateSubject = PassthroughSubject<Void, Never>()
    let shouldSucceed = LockIsolated(false)
    let peripheralManager = PeripheralManager.unimplemented(
      updateValueForCharacteristic: { _, _, _ in
        shouldSucceed.withValue { $0 }
      },
      readyToUpdateSubscribers: readyToUpdateSubject.eraseToAnyPublisher()
    )
    
    var complete = false
    peripheralManager.updateValue(Data(), for: characteristic, onSubscribedCentrals: [central])
      .sink { c in
        complete = true
        if case let .failure(error) = c {
          XCTFail("Unexpected error: \(error)")
        }
      } receiveValue: { _ in
        
      }
      .store(in: &cancellables)
    
    for _ in 1...3 {
      readyToUpdateSubject.send(())
    }
    shouldSucceed.setValue(true)
    readyToUpdateSubject.send(())
    XCTAssert(complete)
  }
}
#endif

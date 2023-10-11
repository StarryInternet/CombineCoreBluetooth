//
//  ContentView.swift
//  PeripheralDemo
//
//  Created by Kevin Lundberg on 3/25/22.
//

import SwiftUI
import CombineCoreBluetooth

extension CBUUID {
  static let service = CBUUID(string: "1337")
  static let writeResponseCharacteristic = CBUUID(string: "0001")
  static let writeNoResponseCharacteristic = CBUUID(string: "0002")
  static let writeBothResponseAndNoResponseCharacteristic = CBUUID(string: "0003")
}

class PeripheralDemo: ObservableObject {
  let peripheralManager = PeripheralManager.live()
  @Published var logs: String = ""
  @Published var advertising: Bool = false
  var cancellables = Set<AnyCancellable>()

  init() {
    peripheralManager.didReceiveWriteRequests
      .receive(on: DispatchQueue.main)
      .sink { [weak self] requests in
        guard let self = self else { return }
        print(requests.map({ r in
          "Write to \(r.characteristic.uuid), value: \(String(bytes: r.value ?? Data(), encoding: .utf8) ?? "<nil>")"
        }).joined(separator: "\n"), to: &self.logs)

        self.peripheralManager.respond(to: requests[0], withResult: .success)
      }
      .store(in: &cancellables)
  }

  func buildServices() {
    let service1 = CBMutableService(type: .service, primary: true)
    let writeCharacteristic = CBMutableCharacteristic(
      type: .writeResponseCharacteristic,
      properties: .write,
      value: nil,
      permissions: .writeable
    )
    let writeNoResponseCharacteristic = CBMutableCharacteristic(
      type: .writeNoResponseCharacteristic,
      properties: .writeWithoutResponse,
      value: nil,
      permissions: .writeable
    )
    let writeWithOrWithoutResponseCharacteristic = CBMutableCharacteristic(
      type: .writeBothResponseAndNoResponseCharacteristic,
      properties: [.write, .writeWithoutResponse],
      value: nil,
      permissions: .writeable
    )

    service1.characteristics = [
      writeCharacteristic,
      writeNoResponseCharacteristic,
      writeWithOrWithoutResponseCharacteristic,
    ]
    peripheralManager.removeAllServices()
    peripheralManager.add(service1)
  }

  func start() {
    peripheralManager.startAdvertising(.init([.serviceUUIDs: [CBUUID.service]]))
      .receive(on: DispatchQueue.main)
      .sink(receiveCompletion: { c in
        
      }, receiveValue: { [weak self] _ in
        self?.advertising = true
        self?.buildServices()
      })
      .store(in: &cancellables)
  }

  func stop() {
    peripheralManager.stopAdvertising()
    cancellables = []
    advertising = false
  }
}

struct PeripheralView: View {
  @StateObject var peripheral: PeripheralDemo = .init()

  var body: some View {
    Form {
      Section("Device that simulates a peripheral with various kinds of characteristics.") {

        if peripheral.advertising {
          Button("Stop advertising") { peripheral.stop() }
        } else {
          Button("Start advertising") { peripheral.start() }
        }

        Text("Logs:")
        Text(peripheral.logs)
      }
    }
    .onAppear {
      peripheral.start()
    }
    .onDisappear {
      peripheral.stop()
    }
  }
}

struct PeripheralView_Previews: PreviewProvider {
  static var previews: some View {
    PeripheralView()
  }
}

//
//  ContentView.swift
//  CentralDemo
//
//  Created by Kevin Lundberg on 3/27/22.
//

import CombineCoreBluetooth
import SwiftUI

class CentralDemo: ObservableObject {
  let centralManager: CentralManager = .live()
  @Published var peripherals: [PeripheralDiscovery] = []
  var scanTask: AnyCancellable?
  @Published var peripheralConnectResult: Result<Peripheral, Error>?
  @Published var scanning: Bool = false

  var connectedPeripheral: Peripheral? {
    guard case let .success(value) = peripheralConnectResult else { return nil }
    return value
  }

  var connectError: Error? {
    guard case let .failure(value) = peripheralConnectResult else { return nil }
    return value
  }

  func searchForPeripherals() {
    scanTask = centralManager.scanForPeripherals(withServices: [CBUUID.service])
      .scan([], { list, discovery -> [PeripheralDiscovery] in
        guard !list.contains(where: { $0.id == discovery.id }) else { return list }
        return list + [discovery]
      })
      .receive(on: DispatchQueue.main)
      .sink(receiveValue: { [weak self] in
        self?.peripherals = $0
      })
    scanning = centralManager.isScanning
  }

  func stopSearching() {
    scanTask = nil
    peripherals = []
    scanning = centralManager.isScanning
  }

  func connect(_ discovery: PeripheralDiscovery) {
    centralManager.connect(discovery.peripheral)
      .map(Result.success)
      .catch({ Just(Result.failure($0)) })
        .receive(on: DispatchQueue.main)
        .assign(to: &$peripheralConnectResult)
  }
}

class PeripheralDevice: ObservableObject {
  let peripheral: Peripheral
  init(_ peripheral: Peripheral) {
    self.peripheral = peripheral
  }

  @Published var writeResponseResult: Result<Date, Error>?
  @Published var writeNoResponseResult: Result<Date, Error>? // never should be set
  @Published var writeResponseOrNoResponseResult: Result<Date, Error>?

  func write(
    to id: CBUUID,
    type: CBCharacteristicWriteType,
    result: ReferenceWritableKeyPath<PeripheralDevice, Published<Result<Date, Error>?>.Publisher>
  ) {
    peripheral.writeValue(
      Data("Hello".utf8),
      writeType: type,
      forCharacteristic: id,
      inService: .service
    )
    .receive(on: DispatchQueue.main)
    .map { _ in Result<Date, Error>.success(Date()) }
    .catch { e in Just(Result.failure(e)) }
    .assign(to: &self[keyPath: result])
  }

  func writeWithoutResponse(to id: CBUUID) {
    writeNoResponseResult = nil

    peripheral.writeValue(
      Data("Hello".utf8),
      writeType: .withoutResponse,
      forCharacteristic: id,
      inService: .service
    )
    .receive(on: DispatchQueue.main)
    .map { _ in Result<Date, Error>.success(Date()) }
    .catch { e in Just(Result.failure(e)) }
    .assign(to: &$writeNoResponseResult)
  }
}

struct CentralView: View {
  @StateObject var demo: CentralDemo = .init()

  var body: some View {
    if let device = demo.connectedPeripheral {
      PeripheralDeviceView(device, demo)
    } else {
      Form {
        Section {
          if !demo.scanning {
            Button("Search for peripheral") {
              demo.searchForPeripherals()
            }
          } else {
            Button("Stop searching") {
              demo.stopSearching()
            }
          }

          if let error = demo.connectError {
            Text("Error: \(String(describing: error))")
          }
        }

        Section("Discovered peripherals") {
          ForEach(demo.peripherals) { discovery in
            Button(discovery.peripheral.name ?? "<nil>") {
              demo.connect(discovery)
            }
          }
        }
      }
    }
  }
}

struct PeripheralDeviceView: View {
  @ObservedObject var device: PeripheralDevice
  @ObservedObject var demo: CentralDemo

  init(_ peripheral: Peripheral, _ demo: CentralDemo) {
    self.device = .init(peripheral)
    self.demo = demo
  }

  var body: some View {
    Form {
      Section("Characteristic sends response") {
        Button(action: {
          device.write(
            to: .writeResponseCharacteristic,
            type: .withResponse,
            result: \PeripheralDevice.$writeResponseResult
          )
        }) {
          Text("Write with response")
        }
        Button(action: {
          device.write(
            to: .writeResponseCharacteristic,
            type: .withoutResponse,
            result: \PeripheralDevice.$writeResponseResult
          )
        }) {
          Text("Write without response")
        }
        label(for: device.writeResponseResult)
      }

      Section("Characteristic doesn't send response") {
        Button(action: {
          device.write(
            to: .writeNoResponseCharacteristic,
            type: .withResponse,
            result: \PeripheralDevice.$writeNoResponseResult
          )
        }) {
          Text("Write with response")
        }
        Button(action: {
          device.write(
            to: .writeNoResponseCharacteristic,
            type: .withoutResponse,
            result: \PeripheralDevice.$writeNoResponseResult
          )
        }) {
          Text("Write without response")
        }
        label(for: device.writeNoResponseResult)
      }

      Section("Characteristic can both send or not send response") {
        Button(action: {
          device.write(
            to: .writeBothResponseAndNoResponseCharacteristic,
            type: .withResponse,
            result: \PeripheralDevice.$writeResponseOrNoResponseResult
          )
        }) {
          Text("Write with response")
        }
        Button(action: {
          device.write(
            to: .writeBothResponseAndNoResponseCharacteristic,
            type: .withoutResponse,
            result: \PeripheralDevice.$writeResponseOrNoResponseResult
          )
        }) {
          Text("Write without response")
        }

        label(for: device.writeResponseOrNoResponseResult)
      }
    }
  }

  func label<T>(for result: Result<T, Error>?) -> some View {
    Group {
      switch result {
      case let .success(value)?:
        Text("Wrote at \(String(describing: value))")
      case let .failure(error)?:
        if let error = error as? LocalizedError, let errorDescription = error.errorDescription {
          Text("Error: \(errorDescription)")
        } else {
          Text("Error: \(String(describing: error))")
        }
      case nil:
        EmptyView()
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    CentralView()
  }
}

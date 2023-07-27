//
//  PeripheralDemoApp.swift
//  PeripheralDemo
//
//  Created by Kevin Lundberg on 3/25/22.
//

import SwiftUI

@main
struct PeripheralDemoApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}

struct ContentView: View {
  var header: LocalizedStringKey {
    #if targetEnvironment(simulator)
    return "WARNING: if you run this in the simulator, live bluetooth communication will not work, as CoreBluetooth does not function in the simulator. Run as a mac/mac catalyst app instead."
    #else
    return ""
    #endif
  }
  
  var body: some View {
    NavigationView {
      Form {
        Section(header) {
          NavigationLink("Simulate a peripheral") {
            PeripheralView()
              .navigationTitle("Peripheral")
          }
          NavigationLink("Simulate a central") {
            CentralView()
              .navigationTitle("Central")
          }
        }
      }
    }
  }
}

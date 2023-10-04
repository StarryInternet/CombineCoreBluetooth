# CombineCoreBluetooth

[![CI](https://github.com/StarryInternet/CombineCoreBluetooth/actions/workflows/ci.yml/badge.svg)](https://github.com/StarryInternet/CombineCoreBluetooth/actions/workflows/ci.yml)
[![GitHub](https://img.shields.io/github/license/StarryInternet/CombineCoreBluetooth)](https://github.com/StarryInternet/CombineCoreBluetooth/blob/master/LICENSE)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FStarryInternet%2FCombineCoreBluetooth%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/StarryInternet/CombineCoreBluetooth)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FStarryInternet%2FCombineCoreBluetooth%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/StarryInternet/CombineCoreBluetooth)

CombineCoreBluetooth is a library that bridges Apple's `CoreBluetooth` framework and Apple's `Combine` framework, making it possible to subscribe to perform bluetooth operations while subscribing to a publisher of the results of those operations, instead of relying on implementing delegates and manually filtering for the results you need.

## Requirements:

- iOS 13, tvOS 13, macOS 10.15, or watchOS 6
- Xcode 13.3 or higher
- Swift 5.6 or higher

## Installation

### Swift Package Manager

Add this line to your dependencies list in your Package.swift:

```swift
.package(name: "CombineCoreBluetooth", url: "https://github.com/StarryInternet/CombineCoreBluetooth.git", from: "0.3.0"),
```

### Cocoapods

Add this line to your Podfile:

```ruby
pod 'CombineCoreBluetooth'
```

### Carthage

Add this line to your Cartfile:

```
github "StarryInternet/CombineCoreBluetooth"
```

## Usage

This library is heavily inspired by [pointfree.co's approach](https://www.pointfree.co/collections/dependencies) to designing dependencies, but with some customizations. Many asynchronous operations returns their own `Publisher` or expose their own long-lived publisher you can subscribe to.

This library doesn't maintain any additional state beyond what's needed to enable this library to provide a combine-centric API. This means that you are responsible for maintaining any state necessary, including holding onto any `Peripheral`s returned by discovering and connected to via the `CentralManager` type.

To scan for a peripheral, much like in plain CoreBluetooth, you call the `scanForPeripherals(withServices:options:)` method. However, on this library's `CentralManager` type, this returns a publisher of `PeripheralDiscovery` values. If you want to store a peripheral for later use, you could subscribe to the returned publisher by doing something like this:

```swift
let serviceID = CBUUID(string: "0123")

centralManager.scanForPeripherals(withServices: [serviceID])
  .first()
  .assign(to: \.peripheralDiscovery, on: self) // property of type PeripheralDiscovery
  .store(in: &cancellables)
```

To do something like fetching a value from a characteristic, for instance, you could call the following methods on the `Peripheral` type and subscribe to the resulting `Publisher`:

```swift
// use whatever ids your peripheral advertises here
let characteristicID = CBUUID(string: "4567")

peripheralDiscovery.peripheral
  .readValue(forCharacteristic: characteristicID, inService: serviceID)
  .sink(receiveCompletion: { completion in
    // handle any potential errors here
  }, receiveValue: { data in
   // handle data from characteristic here, or add more publisher methods to map and transform it.
  })
  .store(in: &cancellables)
```

The publisher returned in `readValue` will only send values that match the service and characteristic IDs through to any subscribers, so you don't need to worry about any filtering logic yourself. Note that if the `Peripheral` never receives a value from this characteristic over bluetooth, it will never send a value into the publisher, so you may want to add a timeout if your use case requires it.

## Caveats

All major types from `CoreBluetooth` should be available in this library, wrapped in their own types to provide the `Combine`-centric API. This library has been tested in production for most `CentralManager` related operations. Apps acting as bluetooth peripherals are also supported using the `PeripheralManager` type, but that side hasn't been as rigorously tested.

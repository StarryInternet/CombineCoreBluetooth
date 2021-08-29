# CombineCoreBluetooth

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FStarryInternet%2FCombineCoreBluetooth%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/StarryInternet/CombineCoreBluetooth)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FStarryInternet%2FCombineCoreBluetooth%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/StarryInternet/CombineCoreBluetooth)
![GitHub](https://img.shields.io/github/license/StarryInternet/CombineCoreBluetooth)

CombineCoreBluetooth is a library that bridges Apple's `CoreBluetooth` framework and Apple's `Combine` framework, making it possible to subscribe to perform bluetooth operations while subscribing to a publisher of the results of those operations, instead of relying on implementing delegates and manually filtering for the results you need.

## Requirements:

* iOS 13, tvOS 13, macOS 10.15, or watchOS 6
* Xcode 12 or higher
* Swift 5.3 or higher

## Usage

This library is heavily inspired by [pointfree.co's approach](https://www.pointfree.co/collections/dependencies) to designing dependencies, but with some customizations. Many asynchronous operations returns their own `Publisher` or expose their own long-lived publisher you can subscribe to. To do something like fetching a value from a characteristic, for instance, you could call the following methods on the `Peripheral` type and subscribe to the resulting `Publisher`:

```swift
// use whatever ids your peripheral advertises here
let serviceID = CBUUID(string: "0123")
let characteristicID = CBUUID(string: "4567")

peripheral
  .discoverCharacteristic(withUUID: characteristicID, inServiceWithUUID: serviceID)
  .flatMap { characteristic in
    peripheral.fetchValue(for: characteristic)
  }
  .map(\.value)
  .sink(receiveCompletion: { completion in /* ... */ }, receiveValue: { data in
   // handle data from characteristic here, or add more publisher methods to map and transform it.
  })
  .store(in: &cancellables)
```

The `Peripheral` type (created and given to you by the `CentralManager` type) here will filter the results from the given delegate methods, and only send values that match the service and characteristic IDs down to subscribers or child publishers. 

## Caveats

All major types from `CoreBluetooth` should be available in this library, wrapped in their own types to provide the `Combine`-centric API. This library has been tested in production for most `CentralManager` related operations. Apps acting as bluetooth peripherals are also supported using the `PeripheralManager` type, but that side hasn't been as rigorously tested.   

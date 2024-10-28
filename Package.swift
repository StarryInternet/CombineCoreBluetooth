// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "CombineCoreBluetooth",
  platforms: [
    .iOS(.v13),
    .macOS(.v11),
    .tvOS(.v13),
    .watchOS(.v6),
  ],
  products: [
    .library(
      name: "CombineCoreBluetooth",
      targets: ["CombineCoreBluetooth"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-concurrency-extras", "0.1.0"..<"2.0.0"),
  ],
  targets: [
    .target(
      name: "CombineCoreBluetooth",
      dependencies: [
      ],
      swiftSettings: [
      ]
    ),
    .testTarget(
      name: "CombineCoreBluetoothTests",
      dependencies: [
        "CombineCoreBluetooth",
        .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
      ]
    ),
  ]
)

// swift-tools-version:5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

#if swift(>=5.6)
let dependencies: [Package.Dependency] = [
  .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
]
#else
let dependencies: [Package.Dependency] = []
#endif

let package = Package(
  name: "CombineCoreBluetooth",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
    .watchOS(.v6),
  ],
  products: [
    .library(
      name: "CombineCoreBluetooth",
      targets: ["CombineCoreBluetooth"]
    ),
  ],
  dependencies: dependencies,
  targets: [
    .target(
      name: "CombineCoreBluetooth",
      dependencies: [],
      swiftSettings: [
        .enableExperimentalFeature("StrictConcurrency")
      ]
    ),
    .testTarget(
      name: "CombineCoreBluetoothTests",
      dependencies: ["CombineCoreBluetooth"]
    ),
  ]
)

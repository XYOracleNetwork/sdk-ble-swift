// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "XyBleSdk",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "sdk-ble-swift",
            targets: ["sdk-ble-swift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/google/promises", from: "1.2.8"),
        .package(url: "https://github.com/XYOracleNetwork/sdk-base-swift.git", from: "1.0.2"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "sdk-ble-swift",
            dependencies: ["Promises"]),
        .testTarget(
            name: "sdk-ble-swiftTests",
            dependencies: ["sdk-ble-swift"]),
    ]    
)

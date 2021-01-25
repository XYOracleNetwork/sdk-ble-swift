// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "XyBleSdk",
  platforms: [
    .iOS(.v8),
    .macOS(.v10_13)
  ],
  products: [
    // Products define the executables and libraries a package produces, and make them visible to other packages.
    .library(
        name: "XyBleSdk",
        targets: ["XyBleSdk"]),
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    // .package(url: /* package url */, from: "1.0.0"),
    .package(name: "Promises", url: "https://github.com/google/promises.git", from: "1.2.8"),
    .package(name: "XyBaseSdk", url: "https://github.com/XYOracleNetwork/sdk-base-swift.git", from: "2.0.0")
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages this package depends on.
    .target(
        name: "XyBleSdk",
        dependencies: ["Promises", "XyBaseSdk"]),
    .testTarget(
        name: "XyBleSdkTests",
        dependencies: ["XyBleSdk"]),
  ]
)

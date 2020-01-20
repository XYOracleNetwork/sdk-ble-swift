// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "XyBleSdk",
    dependencies: [
        .Package(url: "https://github.com/google/promises", versions: Version(1, 2, 4)..<Version(1, 2, 5))
    ]
)

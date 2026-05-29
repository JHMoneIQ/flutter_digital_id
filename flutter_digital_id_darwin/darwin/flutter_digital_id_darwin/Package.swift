// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "flutter_digital_id_darwin",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "flutter-digital-id-darwin",
            targets: ["flutter_digital_id_darwin"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "flutter_digital_id_darwin",
            dependencies: [],
            resources: []
        ),
    ]
)

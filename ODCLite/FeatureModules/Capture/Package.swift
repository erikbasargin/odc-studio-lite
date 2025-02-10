// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Capture",
    products: [
        .library(
            name: "Capture",
            targets: ["Capture"]
        ),
    ],
    targets: [
        .target(
            name: "Capture"
        ),
        .testTarget(
            name: "CaptureTests",
            dependencies: ["Capture"]
        ),
    ]
)

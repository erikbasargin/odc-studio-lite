// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ODCStudioLite",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "Capture",
            targets: [
                "Capture",
            ]
        ),
    ],
    targets: [
        .target(
            name: "Capture",
            dependencies: [
                "Extensions",
            ]
        ),
        .testTarget(
            name: "CaptureTests",
            dependencies: [
                "Capture",
            ]
        ),
        
        .target(
            name: "Extensions"
        ),
        .testTarget(
            name: "ExtensionsTests",
            dependencies: [
                "Extensions",
            ]
        ),
    ]
)

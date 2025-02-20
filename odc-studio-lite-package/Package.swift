// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ODCStudioLite",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "Capture",
            targets: [
                "Capture"
            ]
        )
    ],
    targets: [
        .target(
            name: "Capture",
            dependencies: [
                "AudioVideoKit"
            ]
        ),
        .testTarget(
            name: "CaptureTests",
            dependencies: [
                "Capture",
                "AudioVideoKit",
            ]
        ),
        
        .target(
            name: "AudioVideoKit"
        ),
        .testTarget(
            name: "AudioVideoKitTests",
            dependencies: [
                "AudioVideoKit"
            ]
        ),
    ]
)

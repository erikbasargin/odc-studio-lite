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
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-concurrency-extras", from: "1.3.1")
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
                .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
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

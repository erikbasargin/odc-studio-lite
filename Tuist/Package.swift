// swift-tools-version: 6.3
import PackageDescription

#if TUIST
import ProjectDescription

let packageSettings = PackageSettings(
    productTypes: [
        "ComposableArchitecture": .framework,
        "HaishinKit": .framework,
        "RTMPHaishinKit": .framework,
    ]
)
#endif

let package = Package(
    name: "ODCLite",
    dependencies: [
        .package(id: "HaishinKit.HaishinKit_swift", from: "2.0.1"),
        .package(id: "pointfreeco.swift-composable-architecture", from: "1.25.5"),
        .package(id: "pointfreeco.swift-concurrency-extras", from: "1.3.1"),
        .package(id: "square.Valet", from: "5.1.0"),
    ]
)

// swift-tools-version: 6.3
import PackageDescription

#if TUIST
import ProjectDescription

let packageSettings = PackageSettings(
    // Customize the product types for specific package product
    // Default is .staticFramework
    // productTypes: ["Alamofire": .framework,]
    productTypes: [:]
)
#endif

let package = Package(
    name: "ODCLite",
    dependencies: [
        .package(id: "HaishinKit.HaishinKit_swift", from: "2.0.1"),
        .package(id: "pointfreeco.swift-composable-architecture", from: "1.25.5"),
        .package(id: "pointfreeco.swift-concurrency-extras", from: "1.3.1"),
    ]
)

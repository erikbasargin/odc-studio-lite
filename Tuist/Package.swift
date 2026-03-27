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
        .package(url: "https://github.com/HaishinKit/HaishinKit.swift", exact: "2.0.1"),
        .package(url: "https://github.com/pointfreeco/swift-concurrency-extras", from: "1.3.1"),
    ]
)

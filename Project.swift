import ProjectDescription

let projectBaseSettings: SettingsDictionary = [
    "DEVELOPMENT_TEAM": "S8BXS2P4Z9",
    "CODE_SIGN_STYLE": "Automatic",
    "SWIFT_VERSION": "6",
    "SWIFT_STRICT_CONCURRENCY": "complete",
    "SWIFT_APPROACHABLE_CONCURRENCY": "YES",
    "SWIFT_UPCOMING_FEATURE_6_0": "YES",
    "STRING_CATALOG_GENERATE_SYMBOLS": "YES",
    "RUN_DOCUMENTATION_COMPILER": "YES",
]

let deploymentTargets: DeploymentTargets = .macOS("26.0")

let project = Project(
    name: "ODCLite",
    settings: .settings(base: projectBaseSettings),
    targets: [
        .target(
            name: "ODCLite",
            destinations: .macOS,
            product: .app,
            bundleId: "$(PRODUCT_BUNDLE_IDENTIFIER)",
            deploymentTargets: deploymentTargets,
            infoPlist: "Modules/App/Configurations/Info.plist",
            buildableFolders: [
                "Modules/App/Sources",
                "Modules/App/Resources",
            ],
            entitlements: "Modules/App/Configurations/ODCLite.entitlements",
            dependencies: [
                .target(name: "AudioVideoKit"),
                .external(name: "ComposableArchitecture"),
                .external(name: "HaishinKit"),
                .external(name: "RTMPHaishinKit"),
            ],
            settings: .settings(
                base: [
                    "CODE_SIGN_IDENTITY": "Apple Development",
                    "ENABLE_HARDENED_RUNTIME": "YES",
                ],
                configurations: [
                    .debug(
                        name: "Debug",
                        settings: [
                            "PRODUCT_BUNDLE_IDENTIFIER": "com.odclite.debug",
                        ],
                    ),
                    .release(
                        name: "Release",
                        settings: [
                            "PRODUCT_BUNDLE_IDENTIFIER": "com.odclite",
                        ],
                    ),
                ],
            ),
        ),
        
        .target(
            name: "ODCLiteTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "com.odclite.debug.unitTests",
            deploymentTargets: deploymentTargets,
            buildableFolders: [
                "Modules/App/Tests",
            ],
            dependencies: [
                .target(name: "ODCLite"),
                .target(name: "AudioVideoKit"),
                .external(name: "ComposableArchitecture"),
            ],
            settings: .settings(
                base: [
                    "CODE_SIGN_IDENTITY": "Apple Development",
                ],
            ),
        ),
        
        .target(
            name: "AudioVideoKit",
            destinations: .macOS,
            product: productType(),
            bundleId: "com.odclite.audioVideoKit",
            deploymentTargets: deploymentTargets,
            buildableFolders: [
                "Modules/AudioVideoKit/Sources",
            ],
            settings: .settings(
                base: [
                    "ENABLE_MODULE_VERIFIER": "YES",
                    "MODULE_VERIFIER_SUPPORTED_LANGUAGE_STANDARDS": "gnu11 gnu++14",
                    "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
                ],
            )
        ),
        
        .target(
            name: "AudioVideoKitTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "com.odclite.audioVideoKit.unitTests",
            deploymentTargets: deploymentTargets,
            buildableFolders: [
                "Modules/AudioVideoKit/Tests",
            ],
            dependencies: [
                .target(name: "AudioVideoKit"),
                .external(name: "ConcurrencyExtras"),
            ],
        ),
    ],
    schemes: [
        .scheme(
            name: "ODCLite",
            buildAction: .buildAction(
                targets: ["ODCLite"],
                postActions: [
                    .executionAction(
                        title: "Inspect Build",
                        scriptText: """
                        $HOME/.local/bin/mise x -C $SRCROOT -- tuist inspect build    
                        """,
                        target: "ODCLite",
                    ),
                ],
                runPostActionsOnFailure: true,
            ),
            testAction: .targets([
                "ODCLiteTests",
                "AudioVideoKitTests",
            ]),
        ),
    ]
)

func productType() -> Product {
    switch Environment.productType {
    case .string("static-library"): .staticLibrary
    default: .framework
    }
}

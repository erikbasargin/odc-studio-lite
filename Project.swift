import ProjectDescription

let projectBaseSettings: SettingsDictionary = [
    "DEVELOPMENT_TEAM": "S8BXS2P4Z9",
    "CODE_SIGN_STYLE": "Automatic",
    "SWIFT_VERSION": "6",
    "SWIFT_STRICT_CONCURRENCY": "complete",
    "SWIFT_APPROACHABLE_CONCURRENCY": "YES",
    "SWIFT_UPCOMING_FEATURE_6_0": "YES",
]

let targetBaseSettings: SettingsDictionary = [
    "CODE_SIGN_IDENTITY": "Apple Development",
]

var captureKitBaseSettings: SettingsDictionary {
    var settings = targetBaseSettings
    settings["SWIFT_PACKAGE_NAME"] = "Capture"
    return settings
}

let project = Project(
    name: "ODCLite",
    settings: .settings(base: projectBaseSettings),
    targets: [
        .target(
            name: "ODCLite",
            destinations: .macOS,
            product: .app,
            bundleId: "$(PRODUCT_BUNDLE_IDENTIFIER)",
            deploymentTargets: .macOS("15.0"),
            infoPlist: "Modules/App/Configurations/Info.plist",
            buildableFolders: [
                "Modules/App/Sources",
                "Modules/App/Resources",
            ],
            entitlements: "Modules/App/Configurations/ODCLite.entitlements",
            dependencies: [
                .target(name: "AudioVideoKit"),
                .external(name: "HaishinKit"),
            ],
            settings: .settings(
                base: targetBaseSettings,
                configurations: [
                    .debug(
                        name: "Debug",
                        settings: [
                            "PRODUCT_NAME": "ODC Lite Debug",
                            "PRODUCT_BUNDLE_IDENTIFIER": "com.odclite.debug",
                        ],
                    ),
                    .release(
                        name: "Release",
                        settings: [
                            "PRODUCT_NAME": "ODC Lite",
                            "PRODUCT_BUNDLE_IDENTIFIER": "com.odclite",
                        ],
                    ),
                ],
            ),
        ),
        
        .target(
            name: "AudioVideoKit",
            destinations: .macOS,
            product: .framework,
            bundleId: "com.odclite.audioVideoKit",
            deploymentTargets: .macOS("15.0"),
            buildableFolders: [
                "Modules/AudioVideoKit/Sources",
            ],
            settings: .settings(base: captureKitBaseSettings),
        ),
        
        .target(
            name: "AudioVideoKitTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "com.odclite.audioVideoKit.unitTests",
            deploymentTargets: .macOS("15.0"),
            buildableFolders: [
                "Modules/AudioVideoKit/Tests",
            ],
            dependencies: [
                .target(name: "AudioVideoKit"),
                .external(name: "ConcurrencyExtras"),
            ],
            settings: .settings(base: captureKitBaseSettings),
        ),
    ],
    schemes: [
        .scheme(
            name: "ODCLite",
            buildAction: .buildAction(
                targets: ["ODCLite"],
            ),
            testAction: .targets([
                "AudioVideoKitTests",
            ]),
        ),
    ]
)

import ProjectDescription
import ProjectDescriptionHelpers
import Foundation
import Env

// MARK: - Project

let bundleId = "com.zenangst.Keyboard-Cowboy"

func xcconfig(_ targetName: String) -> String { "Configurations/\(targetName).xcconfig" }
func sources(_ folder: String) -> SourceFilesList { "\(folder)/Sources/**" }
func resources(_ folder: String) -> ResourceFileElements { "\(folder)/Resources/**" }

let envPath = URL(fileURLWithPath: String(#filePath))
    .deletingLastPathComponent()
    .absoluteString
    .replacingOccurrences(of: "file://", with: "")
    .appending(".env")

let env = EnvHelper(envPath)

let project = Project(
    name: "Keyboard Cowboy",
    options: Project.Options.options(
        textSettings: .textSettings(indentWidth: 2,
                                    tabWidth: 2)),
    targets: [
        Target(
            name: "Keyboard-Cowboy",
            platform: .macOS,
            product: .app,
            bundleId: bundleId,
            deploymentTarget: DeploymentTarget.macOS(targetVersion: "12.0"),
            infoPlist: .file(path: .relativeToRoot("App/Info.plist")),
            sources: sources("App"),
            resources: resources("App"),
            entitlements: "App/Entitlements/com.zenangst.Keyboard-Cowboy.entitlements",
            dependencies: [
                .external(name: "Apps"),
                .external(name: "Inject"),
                .external(name: "InputSources"),
                .external(name: "KeyCodes"),
                .external(name: "LaunchArguments"),
                .external(name: "MachPort"),
                .external(name: "Windows"),
            ],
            settings:
                Settings.settings(
                    base: [
                        "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                        "CODE_SIGN_IDENTITY": "Apple Development",
                        "CODE_SIGN_STYLE": "Automatic",
                        "CURRENT_PROJECT_VERSION": "1",
                        "DEVELOPMENT_TEAM": env["TEAM_ID"],
                        "ENABLE_HARDENED_RUNTIME": true,
                        "MARKETING_VERSION": "0.0.1",
                        "PRODUCT_NAME": "Keyboard Cowboy"
                    ],
                    configurations: [
                        .debug(name: "Debug", xcconfig: "\(xcconfig("Debug"))"),
                        .release(name: "Release", xcconfig: "\(xcconfig("Release"))")
                    ],
                    defaultSettings: .recommended)
        ),
        Target(
            name: "UnitTests",
               platform: .macOS,
               product: .unitTests,
               bundleId: bundleId.appending(".unit-tests"),
            deploymentTarget: DeploymentTarget.macOS(targetVersion: "12.0"),
            infoPlist: .file(path: .relativeToRoot("UnitTests/Info.plist")),
            sources: sources("UnitTests"),
            dependencies: [
                .target(name: "Keyboard-Cowboy")
            ],
            settings:
                Settings.settings(base: [
                    "BUNDLE_LOADER": "$(TEST_HOST)",
                    "CODE_SIGN_IDENTITY": "Apple Development",
                    "CODE_SIGN_STYLE": "-",
                    "DEVELOPMENT_TEAM": env["TEAM_ID"],
                    "PRODUCT_BUNDLE_IDENTIFIER": "\(bundleId).UnitTests",
                    "TEST_HOST": "$(BUILT_PRODUCTS_DIR)/Keyboard Cowboy.app/Contents/MacOS/Keyboard Cowboy",
                ])
        )
    ],
    schemes: [
        Scheme(
            name: "Keyboard-Cowboy",
            shared: true,
            hidden: false,
            buildAction: .buildAction(targets: ["Keyboard-Cowboy"]),
            testAction: .targets(
                ["UnitTests"],
                arguments: Arguments(
                    environment: [
                        "SOURCE_ROOT": "$(SRCROOT)"
                    ],
                    launchArguments: [
                        LaunchArgument(name: "-running-unit-tests", isEnabled: true)
                    ])
            ),
            runAction: .runAction(
                executable: "Keyboard-Cowboy",
                arguments: Arguments.init(environment: [
                    "SOURCE_ROOT": "$(SRCROOT)"
                ]))
        )
    ],
    additionalFiles: [
        FileElement(stringLiteral: ".gitignore"),
        FileElement(stringLiteral: ".env"),
        FileElement(stringLiteral: "Project.swift"),
        FileElement(stringLiteral: "Tuist/Dependencies.swift"),
        FileElement(stringLiteral: "Fixtures"),
    ]
)

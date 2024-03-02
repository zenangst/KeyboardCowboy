import ProjectDescription
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
// Main application target
let mainAppTarget = Target.target(
  name: "Keyboard-Cowboy",
  destinations: .macOS,
  product: .app,
  bundleId: "com.zenangst.Keyboard-Cowboy",
  deploymentTargets: .macOS("13.0"),
  infoPlist: .file(path: .relativeToRoot("App/Info.plist")),
  sources: sources("App"),
  resources: resources("App"),
  entitlements: "App/Entitlements/com.zenangst.Keyboard-Cowboy.entitlements",
  dependencies: [
    .package(product: "AXEssibility"),
    .package(product: "Apps"),
    .package(product: "Bonzai"),
    .package(product: "Dock"),
    .package(product: "Inject"),
    .package(product: "InputSources"),
    .package(product: "Intercom"),
    .package(product: "KeyCodes"),
    .package(product: "LaunchArguments"),
    .package(product: "MachPort"),
    .package(product: "Sparkle"),
    .package(product: "Windows"),
  ],
  settings:
    Settings.settings(
      base: [
        "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
        "CODE_SIGN_IDENTITY": "Apple Development",
        "CODE_SIGN_STYLE": "Automatic",
        "CURRENT_PROJECT_VERSION": "576",
        "DEVELOPMENT_TEAM": env["TEAM_ID"],
        "ENABLE_HARDENED_RUNTIME": true,
        "MARKETING_VERSION": "3.23.0",
        "PRODUCT_NAME": "Keyboard Cowboy"
      ],
      configurations: [
        .debug(name: "Debug", xcconfig: "\(xcconfig("Debug"))"),
        .release(name: "Release", xcconfig: "\(xcconfig("Release"))")
      ],
      defaultSettings: .recommended)
)
// Unit Tests
let unitTestTarget = Target.target(
  name: "UnitTests",
  destinations: .macOS,
  product: .unitTests,
  bundleId: bundleId.appending(".unit-tests"),
  deploymentTargets: .macOS("13.0"),
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

let project = Project(
  name: "Keyboard Cowboy",
  options: Project.Options.options(
    textSettings: .textSettings(indentWidth: 2,
                                tabWidth: 2)),
  packages: PackageResolver.packages(env),
  settings: Settings.settings(configurations: [
    .debug(name: "Debug", xcconfig: "\(xcconfig("Debug"))"),
    .release(name: "Release", xcconfig: "\(xcconfig("Release"))")
  ], defaultSettings: .recommended),
  targets: [
    mainAppTarget,
    unitTestTarget
  ],
  schemes: [
    Scheme.scheme(
      name: mainAppTarget.name,
      shared: true,
      hidden: false,
      buildAction: .buildAction(targets: [.target(mainAppTarget.name)]),
      testAction: .targets(
        [.testableTarget(target: .target(unitTestTarget.name))],
        arguments: .arguments(
          environmentVariables: [
            "SOURCE_ROOT": .environmentVariable(value: "$(SRCROOT)", isEnabled: true)
          ],
          launchArguments: [
            .launchArgument(name: "-running-unit-tests", isEnabled: true)
          ])
        ,
        options: .options(
          coverage: true,
          codeCoverageTargets: [.target(mainAppTarget.name)]
        )
      ),
      runAction: .runAction(
        executable: .target(mainAppTarget.name),
        arguments: .arguments(
          environmentVariables: [
            "SOURCE_ROOT": .environmentVariable(value: "$(SRCROOT)", isEnabled: true),
            "APP_ENVIRONMENT_OVERRIDE": .environmentVariable(value: "development", isEnabled: true)
          ],
          launchArguments: [
            .launchArgument(name: "-benchmark", isEnabled: false),
            .launchArgument(name: "-debugEditing", isEnabled: false),
            .launchArgument(name: "-injection", isEnabled: false),
            .launchArgument(name: "-disableMachPorts", isEnabled: false),
          ]
        )
      )
    )
  ],
  additionalFiles: [
    .glob(pattern: .path( ".env")),
    .glob(pattern: .path( ".github/workflows")),
    .glob(pattern: .path( ".gitignore")),
    .glob(pattern: .path( "ci_scripts")),
    .glob(pattern: .path( "Fixtures")),
    .glob(pattern: .path( "Project.swift")),
    .glob(pattern: .path( "README.md")),
    .glob(pattern: .path( "Tuist/Dependencies.swift")),
    .glob(pattern: .path( "appcast.xml")),
    .glob(pattern: .path( "gh-pages")),
    .glob(pattern: .path( "_RELEASE_NOTES.md")),
  ]
)

public enum PackageResolver {
  public static func packages(_ env: EnvHelper) -> [Package] {
    let packages: [Package]
    if env["PACKAGE_DEVELOPMENT"] == "true" {
      packages = [
        .package(url: "https://github.com/krzysztofzablocki/Inject.git", from: "1.1.0"),
        .package(url: "https://github.com/sparkle-project/Sparkle.git", from: "2.4.1"),
        .package(path: "../AXEssibility"),
        .package(path: "../Bonzai"),
        .package(path: "../Apps"),
        .package(path: "../Dock"),
        .package(path: "../InputSources"),
        .package(path: "../Intercom"),
        .package(path: "../KeyCodes"),
        .package(path: "../LaunchArguments"),
        .package(path: "../MachPort"),
        .package(path: "../Windows"),
      ]
    } else {
      packages = [
        .package(url: "https://github.com/krzysztofzablocki/Inject.git", from: "1.1.0"),
        .package(url: "https://github.com/sparkle-project/Sparkle.git", from: "2.4.1"),
        .package(url: "https://github.com/zenangst/AXEssibility.git", from: "0.1.2"),
        .package(url: "https://github.com/zenangst/Bonzai.git", .revision("add6d9c7115a2a3fd9bfa77e5620b72ce4db4596")),
        .package(url: "https://github.com/zenangst/Apps.git", from: "1.4.2"),
        .package(url: "https://github.com/zenangst/Dock.git", from: "1.0.1"),
        .package(url: "https://github.com/zenangst/InputSources.git", from: "1.0.1"),
        .package(url: "https://github.com/zenangst/Intercom.git", .revision("5a340e185e571d058c09ab8b8ad8716098282443")),
        .package(url: "https://github.com/zenangst/KeyCodes.git", from: "4.1.0"),
        .package(url: "https://github.com/zenangst/LaunchArguments.git", from: "1.0.1"),
        .package(url: "https://github.com/zenangst/MachPort.git", from: "4.1.3"),
        .package(url: "https://github.com/zenangst/Windows.git", from: "1.1.0"),
      ]
    }
    return packages
  }
}

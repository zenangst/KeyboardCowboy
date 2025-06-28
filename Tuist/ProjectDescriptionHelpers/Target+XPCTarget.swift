import ProjectDescription

public extension Target {
  static func xpcTarget(_ env: EnvHelper) -> Target {
    Target.target(
      name: "LassoService",
      destinations: .macOS,
      product: .xpc,
      bundleId: "com.zenangst.Keyboard-Cowboy.LassoService",
      deploymentTargets: .macOS("13.0"),
      infoPlist: .file(path: .relativeToRoot("LassoService/Info.plist")),
      sources: SourceFilesList(arrayLiteral: sources("LassoService"), xpcSources()),
      entitlements: "LassoService/Entitlements/com.zenangst.Keyboard-Cowboy.LassoService.entitlements",
      dependencies: [
        .package(product: "Apps"),
        .package(product: "KeyCodes"),
        .package(product: "InputSources"),
        .package(product: "MachPort"),
      ],
      settings: Settings.settings(base: [
        "CODE_SIGN_IDENTITY": "Apple Development",
        "CODE_SIGN_STYLE": "Automatic",
        "DEVELOPMENT_TEAM": env["TEAM_ID"],
        "ENABLE_HARDENED_RUNTIME": true,
        "PRODUCT_NAME": "LassoService",
        "SWIFT_STRICT_CONCURRENCY": "complete",
        "SWIFT_VERSION": "6.0",
      ])
    )
  }
}

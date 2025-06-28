import ProjectDescription


extension Target {
  public static func mainApp(_ bundleId: String, shell: Shell, env: EnvHelper) -> Target {
    let buildNumber = ((try? shell.run("git rev-list --count HEAD")) ?? "x.x.x").trimmingCharacters(in: .whitespacesAndNewlines)
    let target = Target.target(
      name: "Keyboard-Cowboy",
      destinations: .macOS,
      product: .app,
      bundleId: "com.zenangst.Keyboard-Cowboy",
      deploymentTargets: .macOS("13.0"),
      infoPlist: .file(path: .relativeToRoot("App/Info.plist")),
      sources: SourceFilesList(arrayLiteral: sources("App"), xpcSources()),
      resources: resources("App"),
      entitlements: "App/Entitlements/com.zenangst.Keyboard-Cowboy.entitlements",
      dependencies: [
        .package(product: "AXEssibility"),
        .package(product: "Apps"),
        .package(product: "Bonzai"),
        .package(product: "Dock"),
        .package(product: "DynamicNotchKit"),
        .package(product: "Inject"),
        .package(product: "InputSources"),
        .package(product: "Intercom"),
        .package(product: "KeyCodes"),
        .package(product: "LaunchArguments"),
        .package(product: "MachPort"),
        .package(product: "Sparkle"),
        .package(product: "Windows"),
        //    .target(name: "LassoService")
      ],
      settings:
        Settings.settings(
          base: [
            "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
            "CODE_SIGN_IDENTITY": "Apple Development",
            "CODE_SIGN_STYLE": "Automatic",
            "CURRENT_PROJECT_VERSION": SettingValue(stringLiteral: buildNumber),
            "DEVELOPMENT_TEAM": env["TEAM_ID"],
            "ENABLE_HARDENED_RUNTIME": true,
            "MARKETING_VERSION": "3.28.0",
            "PRODUCT_NAME": "Keyboard Cowboy",
            "SWIFT_STRICT_CONCURRENCY": "complete",
            "SWIFT_VERSION": "6.0",
          ],
          configurations: [
            .debug(name: "Debug", xcconfig: "\(xcconfig("Debug"))"),
            .release(name: "Release", xcconfig: "\(xcconfig("Release"))")
          ],
          defaultSettings: .recommended)
    )

    return target
  }
}

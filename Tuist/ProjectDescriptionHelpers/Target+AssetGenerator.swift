import ProjectDescription

public extension Target {
  static func assetGenerator(_ bundleId: String, env: EnvHelper) -> Target {
    Target.target(
      name: "AssetGenerator",
      destinations: .macOS,
      product: .unitTests,
      bundleId: bundleId.appending(".asset-generator"),
      deploymentTargets: .macOS("13.0"),
      infoPlist: .file(path: .relativeToRoot("AssetGenerator/Info.plist")),
      sources: SourceFilesList(arrayLiteral: sources("AssetGenerator")),
      dependencies: [
        .target(name: "Keyboard-Cowboy")
      ],
      settings:
        Settings.settings(base: [
          "BUNDLE_LOADER": "$(TEST_HOST)",
          "CODE_SIGN_IDENTITY": "Apple Development",
          "CODE_SIGN_STYLE": "-",
          "DEVELOPMENT_TEAM": env["TEAM_ID"],
          "PRODUCT_BUNDLE_IDENTIFIER": "\(bundleId).AssetGenerator",
          "TEST_HOST": "$(BUILT_PRODUCTS_DIR)/Keyboard Cowboy.app/Contents/MacOS/Keyboard Cowboy",
        ])
    )
  }
}

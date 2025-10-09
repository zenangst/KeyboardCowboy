import ProjectDescription

public extension Scheme {
  static func assetGenerator(_ assetGeneratorTarget: Target) -> Scheme {
    Scheme.scheme(
      name: "AssetGenerator",
      shared: true,
      hidden: false,
      testAction: .targets(
        [.testableTarget(target: .target(assetGeneratorTarget.name))],
        arguments: .arguments(
          environmentVariables: [
            "ASSET_PATH": .environmentVariable(value: Router.assetPath, isEnabled: true),
            "SOURCE_ROOT": .environmentVariable(value: Router.sourceRoot, isEnabled: true),
          ],
          launchArguments: [
            .launchArgument(name: "-running-unit-tests", isEnabled: true),
          ],
        ),
      ),
    )
  }
}

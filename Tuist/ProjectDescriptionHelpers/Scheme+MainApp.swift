import ProjectDescription

public extension Scheme {
  static func mainApp(_ mainAppTarget: Target, unitTestTarget: Target) -> Scheme {
    Scheme.scheme(
      name: mainAppTarget.name,
      shared: true,
      hidden: false,
      buildAction: .buildAction(targets: [.target(mainAppTarget.name)]),
      testAction: .targets(
        [.testableTarget(target: .target(unitTestTarget.name))],
        arguments: .arguments(
          environmentVariables: [
            "ASSET_PATH": .environmentVariable(value: Router.assetPath, isEnabled: true),
            "SOURCE_ROOT": .environmentVariable(value: Router.sourceRoot, isEnabled: true),
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
            "APP_ENVIRONMENT_OVERRIDE": .environmentVariable(value: "development", isEnabled: true),
            "SOURCE_ROOT": .environmentVariable(value: Router.sourceRoot, isEnabled: true),
          ],
          launchArguments: [
            .launchArgument(name: "-benchmark", isEnabled: false),
            .launchArgument(name: "-debugEditing", isEnabled: false),
            .launchArgument(name: "-injection", isEnabled: false),
            .launchArgument(name: "-disableMachPorts", isEnabled: false),
            .launchArgument(name: "-openWindowAtLaunch", isEnabled: true)
          ]
        )
      )
    )
  }
}

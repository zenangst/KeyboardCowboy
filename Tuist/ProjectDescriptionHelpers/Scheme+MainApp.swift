import ProjectDescription

public extension Scheme {
  enum Kind {
    case production
    case development

    var appEnvironmentOverride: Bool {
      switch self {
      case .production: false
      case .development: true
      }
    }

    var disableMachPorts: Bool {
      switch self {
      case .production: false
      case .development: true
      }
    }

    var injection: Bool {
      switch self {
      case .production: false
      case .development: true
      }
    }

    var openWindowAtLaunch: Bool {
      switch self {
      case .production: false
      case .development: true
      }
    }
  }

  static func app(_ kind: Kind, appTarget: Target, unitTestTarget: Target? = nil) -> Scheme {
    let testableTargets: [TestableTarget] = if let unitTestTarget {
      [.testableTarget(target: .target(unitTestTarget.name))]
    } else {
      []
    }

    return Scheme.scheme(
      name: appTarget.name,
      shared: true,
      hidden: false,
      buildAction: .buildAction(targets: [.target(appTarget.name)]),
      testAction: .targets(
        testableTargets,
        arguments: .arguments(
          environmentVariables: [
            "ASSET_PATH": .environmentVariable(value: Router.assetPath, isEnabled: true),
            "SOURCE_ROOT": .environmentVariable(value: Router.sourceRoot, isEnabled: true),
          ],
          launchArguments: [
            .launchArgument(name: "-running-unit-tests", isEnabled: true),
          ],
        ),

        options: .options(
          coverage: true,
          codeCoverageTargets: [.target(appTarget.name)],
        ),
      ),
      runAction: .runAction(
        executable: .target(appTarget.name),
        arguments: .arguments(
          environmentVariables: [
            "APP_ENVIRONMENT_OVERRIDE": .environmentVariable(value: "development", isEnabled: kind.appEnvironmentOverride),
            "SOURCE_ROOT": .environmentVariable(value: Router.sourceRoot, isEnabled: true),
          ],
          launchArguments: [
            .launchArgument(name: "-benchmark", isEnabled: false),
            .launchArgument(name: "-debugEditing", isEnabled: false),
            .launchArgument(name: "-injection", isEnabled: kind.injection),
            .launchArgument(name: "-disableMachPorts", isEnabled: kind.disableMachPorts),
            .launchArgument(name: "-openWindowAtLaunch", isEnabled: kind.openWindowAtLaunch),
          ],
        ),
      ),
    )
  }
}

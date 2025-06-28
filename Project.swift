import ProjectDescription
import ProjectDescriptionHelpers
import Foundation

// MARK: - Project
let env = EnvHelper(Router.envPath)
let shell = Shell(path: Router.sourceRoot)

let production = ApplicationProperties(
  name: "Keyboard-Cowboy",
  bundleIdentifier: "com.zenangst.Keyboard-Cowboy",
  hardendRuntime: true
)

let development = ApplicationProperties(
  name: "Keyboard-Cowboy-Development",
  bundleIdentifier: "com.zenangst.Keyboard-Cowboy.development",
  hardendRuntime: false
)

let assetGeneratorTarget = Target.assetGenerator(production.bundleIdentifier, env: env)
let mainAppTarget = Target.app(production, shell: shell, env: env)
let developmentAppTarget = Target.app(development, shell: shell, env: env)
let unitTestTarget = Target.unitTest(production.bundleIdentifier, env: env)
let xpcTarget = Target.xpc(env)

let project = Project(
  name: "Keyboard Cowboy",
  options: Project.Options.options(
    textSettings: .textSettings(indentWidth: 2,
                                tabWidth: 2)),
  packages: PackageResolver.packages(env),
  settings: Settings.settings(configurations: [
    .debug(name: "Debug", xcconfig: "\(Target.xcconfig("Debug"))"),
    .release(name: "Release", xcconfig: "\(Target.xcconfig("Release"))")
  ], defaultSettings: .recommended),
  targets: [
    mainAppTarget,
    developmentAppTarget,
    unitTestTarget,
    assetGeneratorTarget,
    xpcTarget,
  ],
  schemes: [
    Scheme.app(.production, appTarget: mainAppTarget, unitTestTarget: unitTestTarget),
    Scheme.app(.development, appTarget: developmentAppTarget, unitTestTarget: unitTestTarget),
    Scheme.assetGenerator(assetGeneratorTarget)
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

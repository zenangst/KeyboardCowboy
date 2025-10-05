import ProjectDescription

public enum PackageResolver {
  public static func packages(_ env: EnvHelper) -> [Package] {
    let packages: [Package]
    if env["PACKAGE_DEVELOPMENT"] == "true" {
      packages = [
        .package(url: "https://github.com/krzysztofzablocki/Inject.git", from: "1.5.2"),
        .package(url: "https://github.com/sparkle-project/Sparkle.git", from: "2.4.1"),
        .package(path: "../AXEssibility"),
        .package(path: "../Apps"),
        .package(path: "../Bonzai"),
        .package(path: "../Dock"),
        .package(path: "../DynamicNotchKit"),
        .package(path: "../InputSources"),
        .package(path: "../Intercom"),
        .package(path: "../KeyCodes"),
        .package(path: "../LaunchArguments"),
        .package(path: "../MachPort"),
        .package(path: "../Windows"),
        .package(path: "Packages/RingBuffer"),
      ]
    } else {
      packages = [
        .package(url: "https://github.com/krzysztofzablocki/Inject.git", from: "1.5.2"),
        .package(url: "https://github.com/sparkle-project/Sparkle.git", from: "2.4.1"),
        .package(url: "https://github.com/zenangst/AXEssibility.git", .branch("main")),
        .package(url: "https://github.com/zenangst/Apps.git", .branch("main")),
        .package(url: "https://github.com/zenangst/Bonzai.git", .branch("main")),
        .package(url: "https://github.com/zenangst/Dock.git", .branch("main")),
        .package(url: "https://github.com/zenangst/DynamicNotchKit", .branch("main")),
        .package(url: "https://github.com/zenangst/InputSources.git", .branch("main")),
        .package(url: "https://github.com/zenangst/Intercom.git", .branch("main")),
        .package(url: "https://github.com/zenangst/KeyCodes.git", .branch("main")),
        .package(url: "https://github.com/zenangst/LaunchArguments.git", .branch("main")),
        .package(url: "https://github.com/zenangst/MachPort.git", .branch("main")),
        .package(url: "https://github.com/zenangst/Windows.git", .branch("main")),
        .package(path: "Packages/RingBuffer"),
      ]
    }
    return packages
  }
}

import ProjectDescription

let dependencies = Dependencies(
    swiftPackageManager: [
      .remote(url: "https://github.com/krzysztofzablocki/Inject.git", requirement: .exact("1.1.0")),
      .remote(url: "https://github.com/zenangst/Apps.git", requirement: .exact("1.3.1")),
      .remote(url: "https://github.com/zenangst/InputSources.git", requirement: .exact("1.0.1")),
      .remote(url: "https://github.com/zenangst/KeyCodes.git", requirement: .exact("4.0.1")),
      .remote(url: "https://github.com/zenangst/LaunchArguments.git", requirement: .exact("1.0.1")),
//      .remote(url: "https://github.com/zenangst/MachPort.git", requirement: .exact("2.1.0")),
      .remote(url: "https://github.com/zenangst/Windows.git", requirement: .exact("1.0.0")),
      .local(path: "../AXEssibility"),
      .local(path: "../MachPort"),
    ],
    platforms: [.macOS]
)

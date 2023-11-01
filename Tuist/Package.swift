// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "PackageName",
  dependencies: [
    .package(url: "https://github.com/krzysztofzablocki/Inject.git", from: "1.1.0"),
    .package(url: "https://github.com/sparkle-project/Sparkle.git", from: "2.4.1"),
    .package(url: "https://github.com/zenangst/AXEssibility.git", from: "0.0.8"),
    .package(url: "https://github.com/zenangst/Bonzai.git", revision: "3cc38ad3fa42dea6d87f57306c1fac550c539b8f"),
    .package(url: "https://github.com/zenangst/Apps.git", from: "1.4.0"),
    .package(url: "https://github.com/zenangst/Dock.git", from: "1.0.1"),
    .package(url: "https://github.com/zenangst/InputSources.git", from: "1.0.1"),
    .package(url: "https://github.com/zenangst/KeyCodes.git", from: "4.0.5"),
    .package(url: "https://github.com/zenangst/LaunchArguments.git", from: "1.0.1"),
    .package(url: "https://github.com/zenangst/MachPort.git", from: "3.0.1"),
    .package(url: "https://github.com/zenangst/Windows.git", from: "1.0.0"),
  ]
)

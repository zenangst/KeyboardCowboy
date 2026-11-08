// swift-tools-version: 6.3
import Foundation
import PackageDescription

var linkerSettings: [LinkerSetting] {
  let isInjectionRunning = ProcessInfo.processInfo.environment["RUNNING_VIA_INJECTION_NEXT"] != nil
  return isInjectionRunning ? [.unsafeFlags(["-Xlinker", "-interposable"])] : []
}

let package = Package(
  name: "Commands",
  platforms: [.macOS(.v14)],
  products: [.library(name: "Commands", targets: ["Commands"])],
  dependencies: [.package(url: "https://github.com/zenangst/Apps.git", branch: "main")],
  targets: [
    .target(name: "Commands", dependencies: [.product(name: "Apps", package: "Apps")],
            path: "Sources", linkerSettings: linkerSettings),
    .testTarget(name: "CommandsTests", dependencies: ["Commands"], path: "Tests"),
  ],
)

// swift-tools-version: 6.3
import Foundation
import PackageDescription

var linkerSettings: [LinkerSetting] {
  let isInjectionRunning = ProcessInfo.processInfo.environment["RUNNING_VIA_INJECTION_NEXT"] != nil
  return isInjectionRunning ? [.unsafeFlags(["-Xlinker", "-interposable"])] : []
}

let package = Package(
  name: "ApplicationSystem",
  platforms: [.macOS(.v14)],
  products: [.library(name: "ApplicationSystem", targets: ["ApplicationSystem"])],
  dependencies: [.package(path: "../RuntimeEnvironment")],
  targets: [
    .target(name: "ApplicationSystem", dependencies: ["RuntimeEnvironment"],
            path: "Sources", linkerSettings: linkerSettings),
    .testTarget(name: "ApplicationSystemTests", dependencies: ["ApplicationSystem"], path: "Tests"),
  ],
)

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
  dependencies: [.package(path: "../CowboyCore")],
  targets: [
    .target(name: "ApplicationSystem", dependencies: ["CowboyCore"],
            path: "Sources", linkerSettings: linkerSettings),
    .testTarget(name: "ApplicationSystemTests", dependencies: ["ApplicationSystem", "CowboyCore"], path: "Tests"),
  ],
)

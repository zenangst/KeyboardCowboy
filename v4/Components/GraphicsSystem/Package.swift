// swift-tools-version: 6.3
import Foundation
import PackageDescription

var linkerSettings: [LinkerSetting] {
  let isInjectionRunning = ProcessInfo.processInfo.environment["RUNNING_VIA_INJECTION_NEXT"] != nil
  return isInjectionRunning ? [.unsafeFlags(["-Xlinker", "-interposable"])] : []
}

let package = Package(
  name: "GraphicsSystem",
  platforms: [.macOS(.v14)],
  products: [.library(name: "GraphicsSystem", targets: ["GraphicsSystem"])],
  dependencies: [.package(path: "../CowboyCore")],
  targets: [.target(name: "GraphicsSystem", dependencies: ["CowboyCore"], path: "Sources", linkerSettings: linkerSettings)],
)

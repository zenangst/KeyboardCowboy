// swift-tools-version: 6.3
import Foundation
import PackageDescription

var linkerSettings: [LinkerSetting] {
  let isInjectionRunning = ProcessInfo.processInfo.environment["RUNNING_VIA_INJECTION_NEXT"] != nil
  return isInjectionRunning ? [.unsafeFlags(["-Xlinker", "-interposable"])] : []
}

let package = Package(
  name: "Injection",
  platforms: [.macOS(.v14)],
  products: [.library(name: "Injection", targets: ["Injection"])],
  targets: [.target(name: "Injection", path: "Sources", linkerSettings: linkerSettings)],
)

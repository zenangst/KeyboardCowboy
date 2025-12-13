// swift-tools-version: 6.0
import PackageDescription

#if TUIST
import struct ProjectDescription.PackageSettings

let packageSettings = PackageSettings(
  // Customize the product types for specific package product
  // Default is .staticFramework
  // productTypes: ["Alamofire": .framework,]
  productTypes: [:],
)
#endif

let package = Package(
  name: "Keyboard Cowboy",
  dependencies: [
    .package(url: "https://github.com/zenangst/AXEssibility.git", branch: "main"),
    .package(url: "https://github.com/zenangst/Bonzai.git", branch: "main"),
    .package(url: "https://github.com/zenangst/MachPort.git", branch: "main"),
    .package(url: "https://github.com/zenangst/Windows.git", branch: "main"),
    .package(url: "git@github.com:johnno1962/HotSwiftUI.git", branch: "main"),
  ],
)

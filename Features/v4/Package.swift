// swift-tools-version: 6.3

import Foundation
import PackageDescription

let swiftSettings: [SwiftSetting] = [
  .unsafeFlags(["-strict-concurrency=complete"]),
  .unsafeFlags([
    "-Xfrontend", "-debug-time-function-bodies",
    "-Xfrontend", "-warn-long-function-bodies=400",
    "-Xfrontend", "-warn-long-expression-type-checking=400",
    "-DDEBUG",
  ], .when(configuration: .debug)),
]

var linkerSettings: [LinkerSetting] {
  let packageDirectory = URL(filePath: #filePath).deletingLastPathComponent()
  let infoPlistPath = packageDirectory.appending(path: "Resources/Info.plist").path()

  let settings: [LinkerSetting] = [
    .unsafeFlags([
      "-Xlinker", "-sectcreate",
      "-Xlinker", "__TEXT",
      "-Xlinker", "__info_plist",
      "-Xlinker", infoPlistPath,
    ]),
    .unsafeFlags(["-Xlinker", "-interposable"], .when(configuration: .debug)),
  ]

  return settings
}

let package = Package(
  name: "AppBundle",
  platforms: [.macOS(.v14)],
  products: [
    .executable(name: "v4", targets: ["AppTarget"]),
  ],
  dependencies: [
    .package(url: "git@github.com:johnno1962/HotSwiftUI.git", exact: "1.2.4"),
  ],
  targets: [
    .executableTarget(
      name: "AppTarget",
      dependencies: [
        .product(name: "HotSwiftUI", package: "HotSwiftUI"),
      ],
      path: "Sources",
      swiftSettings: swiftSettings,
      linkerSettings: linkerSettings,
    ),
  ],
)

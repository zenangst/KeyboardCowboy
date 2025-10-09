import Foundation
import SwiftUI

enum AssetGenerator {
  @MainActor
  static func generate(filename: String, useIntrinsicContentSize: Bool = false, size: CGSize, content: @autoclosure () -> some View) async throws {
    try await generate(filename: filename, useIntrinsicContentSize: useIntrinsicContentSize, size: size, content: content)
  }

  @MainActor
  static func generate(filename: String, useIntrinsicContentSize: Bool = false, size: CGSize, content: () -> some View) async throws {
    guard let assetRoot = ProcessInfo.processInfo.environment["ASSET_PATH"] else { return }

    let hostingView = NSHostingView(rootView: content()
      .environment(\.colorScheme, .dark))
    hostingView.frame = NSRect(origin: .zero, size: size)

    if useIntrinsicContentSize { hostingView.frame = NSRect(origin: .zero, size: hostingView.intrinsicContentSize) }

    let window = NSWindow(contentRect: hostingView.frame, styleMask: [], backing: .buffered, defer: false)
    window.contentView = hostingView

    let imageRep = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds)
    hostingView.cacheDisplay(in: hostingView.bounds, to: imageRep!)

    guard let imageData = imageRep?.representation(using: .png, properties: [:]) else { return }

    let path = "\(filename).png"
    let url = URL(fileURLWithPath: assetRoot).appendingPathComponent(path)
    let folder = (url.absoluteString as NSString)
      .deletingLastPathComponent
      .replacingOccurrences(of: "file:", with: "")
    let fileManager = FileManager.default

    if !fileManager.fileExists(atPath: folder) {
      try fileManager.createDirectory(
        atPath: folder,
        withIntermediateDirectories: true,
        attributes: nil,
      )
    }

    try imageData.write(to: url)
  }
}

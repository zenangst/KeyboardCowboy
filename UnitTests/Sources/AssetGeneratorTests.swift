import XCTest
import SwiftUI
@testable import Keyboard_Cowboy

@MainActor
final class AssetGeneratorTests: XCTestCase {

  func test_generateIcons() {
    let size: CGFloat = 24
    let imageRenderer = ImageRenderer(content: MagicVarsIconView(size: size))

    guard let assetRoot = ProcessInfo.processInfo.environment["ASSET_PATH"],
          let image = imageRenderer.nsImage,
          let data = image.tiffRepresentation else { return }

    let imageRep = NSBitmapImageRep(data: data)
    guard let imageData = imageRep?.representation(using: .png, properties: [:]) else { return }

    let url = URL(fileURLWithPath: assetRoot)
      .appending(path: "Magic.png")

    do {
      try imageData.write(to: url)
    } catch {
      print("failed to write to disk. url: \(url)")
    }

  }
}

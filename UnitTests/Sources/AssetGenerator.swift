import Foundation
import SwiftUI

final class AssetGenerator {
  @MainActor
  static func generate<T: View>(filename: String, size: CGFloat, content: @autoclosure () -> T) throws {
    try generate(filename: filename, size: size, content: content)
  }

  @MainActor
  static func generate<T: View>(filename: String, size: CGFloat, content: () -> T) throws {
    let imageRenderer = ImageRenderer(content: 
                                        content()
      .environment(\.colorScheme, .dark)
    )

    guard let assetRoot = ProcessInfo.processInfo.environment["ASSET_PATH"],
          let image = imageRenderer.nsImage,
          let data = image.tiffRepresentation else { return }

    let imageRep = NSBitmapImageRep(data: data)
    guard let imageData = imageRep?.representation(using: .png, properties: [:]) else { return }

    let path = "\(filename)_\(Int(size)).png"
    let url = URL(fileURLWithPath: assetRoot)
      .appending(path: path)

    try imageData.write(to: url)

  }
}

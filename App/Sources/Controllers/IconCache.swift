import Cocoa
import Foundation

enum IconCacheError: Error {
  case unableToObtainTiffRepresentation
  case unableToCreateImageRepresentation
  case unableToCreateDataFromImageRepresentation
}

final class IconCache {
  let cache = NSCache<NSString, NSImage>()

  public static var shared = IconCache()

  private init() {}

  public func loadFromCache(at path: String, bundleIdentifier: String, size: CGSize) -> NSImage? {
    let identifier: String = "\(bundleIdentifier)_\(size.suffix).tiff"
    return cache.object(forKey: identifier as NSString)
  }

  public func icon(at path: String, bundleIdentifier: String, size: CGSize) async -> NSImage? {
    let identifier: String = "\(bundleIdentifier)_\(size.suffix).tiff"
    // Load from in-memory cache
    if let inMemoryImage = cache.object(forKey: identifier as NSString) {
      return inMemoryImage
    }

    // Load from disk
    var image: NSImage
    if let imageFromDisk = try? await load(identifier) {
      image = imageFromDisk
    } else {

      if path.hasSuffix("icns") {
        image = NSImage(byReferencing: URL(filePath: path))
      } else {
        image = NSWorkspace.shared.icon(forFile: path)
      }

      var imageRect: CGRect = .init(origin: .zero, size: size)
      let imageRef = image.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)
      if let imageRef = imageRef {
        image = NSImage(cgImage: imageRef, size: imageRect.size)
      }
    }

    try? await save(image, identifier: identifier)

    cache.setObject(image, forKey: identifier as NSString)

    return image
  }

  // MARK: Private methods

  private func load(_ identifier: String) async throws -> NSImage? {
    let url = try applicationCacheDirectory().appending(component: identifier)

    if FileManager.default.fileExists(atPath: url.path()) {
      return NSImage(contentsOf: url)
    }
    return nil
  }

  private func save(_ image: NSImage, identifier: String) async throws {
    let url = try applicationCacheDirectory().appending(component: identifier)

    guard let tiff = image.tiffRepresentation else {
      throw IconCacheError.unableToObtainTiffRepresentation
    }

    guard let imgRep = NSBitmapImageRep(data: tiff) else {
      throw IconCacheError.unableToCreateImageRepresentation
    }

    guard let data = imgRep.representation(using: .tiff, properties: [:]) else {
      throw IconCacheError.unableToCreateDataFromImageRepresentation
    }

    try data.write(to: url)
  }

  private func applicationCacheDirectory() throws -> URL {
    let url = try FileManager.default.url(for: .cachesDirectory,
                                          in: .userDomainMask,
                                          appropriateFor: nil,
                                          create: true)
      .appendingPathComponent(Bundle.main.bundleIdentifier!)
      .appendingPathComponent("IconCache")

    if !FileManager.default.fileExists(atPath: url.path) {
      try FileManager.default.createDirectory(at: url,
                                              withIntermediateDirectories: true,
                                              attributes: nil)
    }

    return url
  }
}

private extension CGSize {
  var suffix: String { "\(Int(width))x\(Int(height))" }
}

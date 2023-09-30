import Cocoa
import Foundation

enum IconCacheError: Error {
  case unableToObtainTiffRepresentation
  case unableToCreateImageRepresentation
  case unableToCreateDataFromImageRepresentation
}

actor IconCache {
  private let cache = NSCache<NSString, NSData>()

  public static var shared = IconCache()

  private init() {}

  public func iconFromCache(at path: String, bundleIdentifier: String, size: CGSize) -> Data? {
    let identifier: String = "\(bundleIdentifier)_\(size.suffix).tiff"
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: " ", with: "-")

    if let inMemoryImage = cache.object(forKey: identifier as NSString) {
      return inMemoryImage as Data
    }
    return nil
  }

  public func icon(at path: String, bundleIdentifier: String, size: CGSize) -> Data? {
    let identifier: String = "\(bundleIdentifier)_\(size.suffix).tiff"
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: " ", with: "-")

    // Load from in-memory cache
    if let inMemoryImage = cache.object(forKey: identifier as NSString) {
      return inMemoryImage as Data
    }

    // Load from disk
    var image: NSImage
    if let dataFromDisk = try? load(identifier) {
      cache.setObject(dataFromDisk as NSData, forKey: identifier as NSString)
      return dataFromDisk
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

    image.size = size

    return try? save(image, identifier: identifier)
  }

  // MARK: Private methods

  private func load(_ identifier: String) throws -> Data? {
    let url = try AppCache.domain("IconCache").appending(component: identifier)

    if FileManager.default.fileExists(atPath: url.path()) {
      return try? Data(contentsOf: url)
    }

    return nil
  }

  private func save(_ image: NSImage, identifier: String) throws -> Data {
    let url = try AppCache.domain("IconCache").appending(component: identifier)

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

    cache.setObject(data as NSData, forKey: identifier as NSString)

    return data
  }
}

private extension CGSize {
  var suffix: String { "\(Int(width))x\(Int(height))" }
}

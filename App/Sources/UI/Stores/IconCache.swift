import Cocoa
import Foundation

enum IconCacheError: Error {
  case unableToObtainTiffRepresentation
  case unableToCreateImageRepresentation
  case unableToCreateDataFromImageRepresentation
}

actor IconCache {
  private let cache = NSCache<NSString, CGImage>()

  public static var shared = IconCache()

  private init() {}

  public func icon(at path: String, bundleIdentifier: String, size: CGSize) async -> CGImage? {

    let identifier: String = "\(bundleIdentifier)_\(size.suffix).tiff"
    // Load from in-memory cache
    if let inMemoryImage = cache.object(forKey: identifier as NSString) {
      return inMemoryImage
    }

    // Load from disk
    var image: NSImage
    if let imageFromDisk = try? await load(identifier) {
      image = NSImage(cgImage: imageFromDisk, size: size)
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

    guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
      return nil
    }

    cache.setObject(cgImage, forKey: identifier as NSString)

    return cgImage
  }

  // MARK: Private methods

  private func load(_ identifier: String) async throws -> CGImage? {
    let identifier = identifier.replacingOccurrences(of: "/", with: "_")
    let url = try applicationCacheDirectory().appending(component: identifier)

    if FileManager.default.fileExists(atPath: url.path()) {
      return NSImage(contentsOf: url)?.cgImage(forProposedRect: nil, context: nil, hints: nil)
    }

    return nil
  }

  private func save(_ image: NSImage, identifier: String) async throws {
    let identifier = identifier.replacingOccurrences(of: "/", with: "_")
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

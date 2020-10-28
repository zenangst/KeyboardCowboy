import Foundation
import Cocoa
import ModelKit
import OSLog

enum IconControllerError: Error {
  case tiffRepresentationFailed
  case bitmapImageRepFailed
  case representationUsingTiffFailed
  case saveImageToDestinationFailed(URL)
}

public class IconController: ObservableObject {
  fileprivate let osLog = OSLog(subsystem: "com.zenangst.Keyboard-Cowboy",
                                category: String(describing: IconController.self))
  @Published var icon: NSImage?
  public static var installedApplications = [Application]()
  private(set) public static var cache = NSCache<NSString, NSImage>()
  private let queue: DispatchQueue = .init(label: "com.zenangst.Keyboard-Cowboy.IconController",
                                           qos: .userInteractive)
  private let fileManager: FileManager
  private let workspace: NSWorkspace

  init(fileManager: FileManager = .init(),
       workspace: NSWorkspace = .shared) {
    self.fileManager = fileManager
    self.workspace = workspace
  }

  public static func clearAll() {
    cache.removeAllObjects()
  }

  public func preLoadIcon(identifier: String, at path: String, size: CGSize) {
    os_signpost(.begin, log: osLog, name: #function)
    defer { os_signpost(.end, log: osLog, name: #function) }
    let cacheKey = "\(identifier)_\(size.string)" as NSString
    guard let image = Self.cache.object(forKey: cacheKey) else {
      return
    }
    self.icon = image
  }

  public func loadIcon(identifier: String, at path: String, size: CGSize) {
    queue.async { [weak self] in
      self?._loadIcon(identifier: identifier, at: path, size: size)
    }
  }

  public func _loadIcon(identifier: String, at path: String, size: CGSize) {
    let cacheKey = "\(identifier)_\(size.string)" as NSString
    os_signpost(.begin, log: osLog, name: "loadIcon")
    defer { os_signpost(.end, log: osLog, name: "loadIcon") }
    if let image = Self.cache.object(forKey: cacheKey) {
      commit(image)
      return
    } else if let cachedImage = loadImageFromDisk(withFilename: identifier, size: size) {
      Self.cache.setObject(cachedImage, forKey: cacheKey)
      commit(cachedImage)
      return
    }

    var applicationPath = path

    if let application = Self.installedApplications
        .first(where: { $0.bundleIdentifier.lowercased() == identifier.lowercased() }) {
      applicationPath = application.path
    }

    var image = self.workspace.icon(forFile: applicationPath)
    var imageRect: CGRect = .init(origin: .zero, size: size)
    let imageRef = image.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)

    if let imageRef = imageRef {
      image = NSImage(cgImage: imageRef, size: imageRect.size)
    }

    try? self.saveImageToDisk(image, withFilename: identifier, size: size)
    Self.cache.setObject(image, forKey: cacheKey)
    self.commit(image)
  }

  private func commit(_ image: NSImage) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.icon = image
    }
  }

  private func tiffDataFromImage(_ image: NSImage) throws -> Data {
    guard let tiff = image.tiffRepresentation else { throw IconControllerError.tiffRepresentationFailed }
    guard let imgRep = NSBitmapImageRep(data: tiff) else { throw IconControllerError.bitmapImageRepFailed }
    guard let data = imgRep.representation(using: .png, properties: [:]) else {
      throw IconControllerError.representationUsingTiffFailed
    }

    return data
  }

  private func loadImageFromDisk(withFilename filename: String, size: CGSize) -> NSImage? {
    guard let applicationFile = try? applicationCacheDirectory()
            .appendingPathComponent("\(filename)_\(size.string).png"),
          FileManager.default.fileExists(atPath: applicationFile.path) else {
      return nil
    }

    return NSImage(contentsOfFile: applicationFile.path)
  }

  func saveImage(_ image: NSImage, to destination: URL, override: Bool = false) throws {
    let data = try tiffDataFromImage(image)
    do {
      if fileManager.fileExists(atPath: destination.path), override == false {
        try fileManager.removeItem(at: destination)
      }
      try data.write(to: destination)
    } catch {
      throw IconControllerError.saveImageToDestinationFailed(destination)
    }
  }

  private func saveImageToDisk(_ image: NSImage, withFilename fileName: String, size: CGSize) throws {
    let applicationFile = try applicationCacheDirectory()
      .appendingPathComponent("\(fileName)_\(size.string).png")
    try saveImage(image, to: applicationFile)
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
  var string: String {
    return "\(Int(width))x\(Int(height))"
  }
}

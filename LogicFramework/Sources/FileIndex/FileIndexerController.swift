import Foundation
import Combine
import CoreGraphics
import OSLog

protocol FileIndexControlling: AnyObject {
  func asyncIndex<T>(with patterns: [FileIndexPattern], match: @escaping (URL) -> Bool,
                     handler: @escaping (URL) -> T?) -> AnyPublisher<[T], Never>
  func index<T>(with patterns: [FileIndexPattern], match: (URL) -> Bool, handler: (URL) -> T?) -> [T]
}

public enum FileIndexPattern {
  case ignorePattern(String)
  case ignorePathExtension(String)
  case ignoreLastPathComponent(String)
}

/// A file index controller iterates of the file-system to produce
/// object that can represent the contents found on disk.
///
/// The internal algorithm is based on pattern matching.
/// It supports different types of patterns, such as:
///
/// - `.ignoreLastPathComponent`: Verify that the current paths
///   last component is does not match.
/// - `.ignoredPathExtensions`: Verify that the current paths extension
///   does not match.
/// - `.ignorePattern`: Verify that the current path does not contain
///   the ignored pattern.
///
/// If a match occurs, the enumerator will skip looking for
/// any descendants inside the current path and continue iterating.
///
/// - Note: All matching is done by calling `.contains` using `String`'s.
///         Patterns do currently not support any form of regular expressions.
///         Adding more patterns increases the overall speed of the algorithm
///         as by default, everything is included.
///
/// The class supports both synchronous and asynchronous indexing.
/// Asynchronousity is achieved using Combine.
///
public final class FileIndexController: FileIndexControlling {
  fileprivate let osLog = OSLog(subsystem: "com.zenangst.Keyboard-Cowboy",
                                category: String(describing: FileIndexController.self))
  let baseUrl: URL

  public init(baseUrl: URL) {
    self.baseUrl = baseUrl
  }

  public func asyncIndex<T>(with patterns: [FileIndexPattern], match: @escaping (URL) -> Bool,
                            handler: @escaping (URL) -> T?) -> AnyPublisher<[T], Never> {
    Just(index(with: patterns, match: match, handler: { handler($0) })).eraseToAnyPublisher()
  }

  public func index<T>(with patterns: [FileIndexPattern], match: (URL) -> Bool, handler: (URL) -> T?) -> [T] {
    let signpostID = OSSignpostID(log: osLog, object: NSString(string: baseUrl.absoluteString))
    os_signpost(.begin, log: osLog, name: #function, signpostID: signpostID, "%@ - Start", baseUrl.absoluteString)
    let fileManager = FileManager()
    let enumerator = fileManager.enumerator(at: baseUrl,
                                            includingPropertiesForKeys: nil,
                                            options: [.skipsHiddenFiles])!

    var ignoredPatterns = Set<URL>()
    var ignoredPathExtensions = Set<String>()
    var ignoredLastPathComponents = Set<String>()
    for pattern in patterns {
      switch pattern {
      case .ignoreLastPathComponent(let pathComponent):
        ignoredLastPathComponents.insert(pathComponent)
      case .ignorePathExtension(let pathExtension):
        ignoredPathExtensions.insert(pathExtension)
      case .ignorePattern(let pattern):
        let url = URL(fileURLWithPath: (pattern as NSString).expandingTildeInPath)
        ignoredPatterns.insert(url)
      }
    }

    var items = [T]()
    for case let fileURL as URL in enumerator {
      let signpostID = OSSignpostID(log: osLog, object: NSString(string: fileURL.path))
      os_signpost(.begin, log: osLog, name: "pathParsing", signpostID: signpostID, "%@ - Start", fileURL.path)
      defer { os_signpost(.end, log: osLog, name: "pathParsing", signpostID: signpostID, "%@ - Start", fileURL.path) }

      // Exclude .git directories
      if fileManager.fileExists(atPath: fileURL.path.appending("/.git")) {
        enumerator.skipDescendants()
      }

      if ignoredLastPathComponents.contains(fileURL.lastPathComponent) ||
          ignoredPathExtensions.contains(fileURL.pathExtension) ||
          ignoredPatterns.contains(fileURL) {
        enumerator.skipDescendants()
        continue
      }

      guard match(fileURL) else { continue }

      os_signpost(.begin, log: osLog, name: "applicationParsing", signpostID: signpostID, "%@ - Start", fileURL.path)
      if let object = handler(fileURL) {
        items.append(object)
      }
      os_signpost(.end, log: osLog, name: "applicationParsing", signpostID: signpostID, "%@ - End", fileURL.path)

      enumerator.skipDescendents()
    }

    os_signpost(.end, log: osLog, name: #function, signpostID: signpostID, "%@ - End", baseUrl.absoluteString)

    return items
  }
}

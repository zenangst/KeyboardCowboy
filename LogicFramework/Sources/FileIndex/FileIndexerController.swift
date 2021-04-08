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
  let urls: [URL]

  public init(urls: [URL]) {
    self.urls = urls
  }

  public func asyncIndex<T>(with patterns: [FileIndexPattern], match: @escaping (URL) -> Bool,
                            handler: @escaping (URL) -> T?) -> AnyPublisher<[T], Never> {
    Just(index(with: patterns, match: match, handler: { handler($0) })).eraseToAnyPublisher()
  }

  public func index<T>(with patterns: [FileIndexPattern], match: (URL) -> Bool, handler: (URL) -> T?) -> [T] {
    var items = [T]()

    for url in urls {
      let signpostID = OSSignpostID(log: osLog, object: NSString(string: url.absoluteString))
      os_signpost(.begin, log: osLog, name: #function, signpostID: signpostID, "%@ - Start", url.absoluteString)
      let fileManager = FileManager()
      let enumerator = fileManager.enumerator(at: url,
                                              includingPropertiesForKeys: nil,
                                              options: [.skipsHiddenFiles])!

      while let fileURL = enumerator.nextObject() as? URL {
        let signpostID = OSSignpostID(log: osLog, object: NSString(string: fileURL.path))
        os_signpost(.end, log: osLog, name: "pathParsing", signpostID: signpostID, "%@ - End", fileURL.path)

        Swift.print(fileURL)




        guard match(fileURL) else {
          os_signpost(.end, log: osLog, name: "pathParsing", signpostID: signpostID, "%@ - End", fileURL.path)
          continue
        }

        if let object = handler(fileURL) {
          items.append(object)
        }
        os_signpost(.end, log: osLog, name: "pathParsing", signpostID: signpostID, "%@ - End", fileURL.path)
        enumerator.skipDescendents()
      }
      os_signpost(.end, log: osLog, name: #function, signpostID: signpostID, "%@ - End", url.absoluteString)
    }

    return items
  }
}

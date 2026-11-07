import AppKit
import Foundation

extension Open {
  enum Environment: Sendable {
    case production
    #if DEBUG
      case testing
    #endif
  }

  struct System: Sendable {
    let environment: Environment

    func open(_ url: URL, applicationURL: URL?) async throws {
      switch environment {
      case .production:
        let configuration = NSWorkspace.OpenConfiguration()
        if let applicationURL {
          _ = try await NSWorkspace.shared.open([url], withApplicationAt: applicationURL, configuration: configuration)
        } else {
          _ = try await NSWorkspace.shared.open(url, configuration: configuration)
        }
      #if DEBUG
        case .testing:
          try await Testing.mock.open(url, applicationURL)
      #endif
      }
    }

    func isDirectory(_ path: String) throws -> Bool {
      switch environment {
      case .production:
        return try URL(fileURLWithPath: path).resourceValues(forKeys: [.isDirectoryKey]).isDirectory ?? false
      #if DEBUG
        case .testing:
          return try Testing.mock.isDirectory(path)
      #endif
      }
    }
  }
}

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

    func firstRunningProcess(bundleIdentifier: String) -> pid_t? {
      switch environment {
      case .production:
        return NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first?.processIdentifier
      #if DEBUG
        case .testing:
          return Testing.mock.firstRunningProcess(bundleIdentifier)
      #endif
      }
    }

    @discardableResult
    func activate(processIdentifier: pid_t) -> Bool {
      switch environment {
      case .production:
        return NSRunningApplication(processIdentifier: processIdentifier)?.activate(options: .activateIgnoringOtherApps) ?? false
      #if DEBUG
        case .testing:
          return Testing.mock.activate(processIdentifier)
      #endif
      }
    }

    func openDefault(_ url: URL) -> Bool {
      switch environment {
      case .production:
        return NSWorkspace.shared.open(url)
      #if DEBUG
        case .testing:
          return Testing.mock.openDefault(url)
      #endif
      }
    }

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

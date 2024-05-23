import Foundation

enum Env {
  static let sourceRoot = ProcessInfo.processInfo.environment["SOURCE_ROOT"] ?? "SOURCE_ROOT"
}

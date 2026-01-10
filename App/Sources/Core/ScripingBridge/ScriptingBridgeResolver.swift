import Foundation

enum SupportedApp: String {
  case finder = "com.apple.finder"
}

enum ScriptingBridgeResolver {
  @MainActor
  static func resolve(_ bundleIdentifier: String,
                      firstUrl: inout String?,
                      selections: inout [String]) {
    guard let supportedApp = SupportedApp(rawValue: bundleIdentifier) else {
      return
    }

    switch supportedApp {
    case .finder:
      SBFinder.getSelections(&firstUrl, selections: &selections)
    }
  }
}

import Foundation

struct Configuration {
  struct Storage {
    var path: String {
      launchArguments.isEnabled(.demoMode)
      ? ProcessInfo.processInfo.environment["SOURCE_ROOT"]!
      : UserDefaults.standard.string(forKey: "configurationPath") ?? "~"
    }
    var hiddenFile: Bool = true
    var fileName: String {
      (hiddenFile && !launchArguments.isEnabled(.demoMode))
        ? ".keyboard-cowboy.json"
        : "keyboard-cowboy.json"
    }
  }
}

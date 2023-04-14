import Foundation

struct Configuration {
  struct Storage {
    /// The path to the configuration file
    var path: String {
      launchArguments.isEnabled(.demoMode)
      ? ProcessInfo.processInfo.environment["SOURCE_ROOT"]!
      : UserDefaults.standard.string(forKey: "configurationPath") ?? "~"
    }
    /// Determines if the file name should use `.` as a prefix in order
    /// to hide it in the Finder
    var hiddenFile: Bool = true
    /// A computed variable that changes depending on `hiddenFile`.
    /// The file name is either `.keyboard-cowboy.json` or `keyboard-cowboy.json`
    var fileName: String {
      (hiddenFile && !launchArguments.isEnabled(.demoMode))
        ? ".keyboard-cowboy.json"
        : "keyboard-cowboy.json"
    }
  }
}

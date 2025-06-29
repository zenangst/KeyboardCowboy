import Foundation

struct ConfigurationLocation: Equatable {
  var path: String
  var filename: String
  var url: URL {
    URL(fileURLWithPath: path).appendingPathComponent(filename)
  }

  init(path: String, filename: String) {
    self.path = (path as NSString).expandingTildeInPath
    self.filename = filename
  }
}

extension ConfigurationLocation {
  @MainActor
  private static var fileName: String {
    if KeyboardCowboyApp.bundleIdentifier == "com.zenangst.Keyboard-Cowboy" {
      "config.json"
    } else {
      "config-dev.json"
    }
  }
  private static var jsonFixuresFolder: String { rootFolder.appending("/Fixtures/json") }

  @MainActor
  static var user: ConfigurationLocation {
    ConfigurationLocation(path: "~/.config/keyboardcowboy/", filename: Self.fileName)
  }

  static var designTime: ConfigurationLocation {
    ConfigurationLocation(path: jsonFixuresFolder, filename: "designTime.json")
  }

  static var performance: ConfigurationLocation {
    ConfigurationLocation(path: jsonFixuresFolder, filename: "designTime.json")
  }
}

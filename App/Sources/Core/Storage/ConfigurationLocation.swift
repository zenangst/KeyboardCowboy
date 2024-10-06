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
  private static var jsonFixuresFolder: String { rootFolder.appending("/KeyboardCowboy/Fixtures/json") }

  static var user: ConfigurationLocation {
    ConfigurationLocation(path: "~/.config/keyboardcowboy/", filename: ".keyboard-cowboy.json")
  }

  static var legacy: ConfigurationLocation {
    ConfigurationLocation(path: "~/", filename: ".keyboard-cowboy.json")
  }

  static var designTime: ConfigurationLocation {
    ConfigurationLocation(path: jsonFixuresFolder, filename: "designTime.json")
  }

  static var performance: ConfigurationLocation {
    ConfigurationLocation(path: jsonFixuresFolder, filename: "designTime.json")
  }
}

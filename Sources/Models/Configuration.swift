import Cocoa

struct AppPreferences {
  var hideAppOnLaunch: Bool = false
  var storageConfiguration: StorageConfiguration

  static func designTime() -> AppPreferences {
    AppPreferences(
      hideAppOnLaunch: false,
      storageConfiguration: .init(path: "~/Developer/KC",
                                  filename: "dummyData.json"))
  }
}

struct StorageConfiguration {
  var path: String
  var filename: String
  var url: URL {
    URL(fileURLWithPath: path).appendingPathComponent(filename)
  }

  internal init(path: String, filename: String) {
    self.path = (path as NSString).expandingTildeInPath
    self.filename = filename
  }
}

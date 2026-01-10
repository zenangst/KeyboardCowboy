import Apps
import Foundation

/// This command is used to open folders, files, web
/// or custom urls.
struct OpenCommand: MetaDataProviding {
  /// If `application` is `nil`, then it should use the
  /// default application that matches the current url
  let application: Application?
  /// The difference here is that `path` is forced to be a
  /// file-path (file://). There will most certainly be a
  /// difference between the two in terms of UI.
  var path: String
  var meta: Command.MetaData

  var isUrl: Bool {
    if let url = URL(string: path) {
      if url.host == nil || url.isFileURL {
        false
      } else {
        true
      }
    } else {
      false
    }
  }

  init(id: String = UUID().uuidString,
       name: String = "",
       application: Application? = nil, path: String,
       notification: Command.Notification? = nil) {
    self.application = application
    self.path = path
    meta = Command.MetaData(id: id, name: name, isEnabled: true, notification: notification)
  }

  init(application: Application?, path: String, meta: Command.MetaData) {
    self.application = application
    self.path = path
    self.meta = meta
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    application = try container.decodeIfPresent(Application.self, forKey: .application)
    path = try container.decode(String.self, forKey: .path)
    meta = try container.decode(Command.MetaData.self, forKey: .meta)
  }

  func copy() -> OpenCommand {
    OpenCommand(application: application, path: path, meta: meta.copy())
  }
}

extension OpenCommand {
  static func empty() -> OpenCommand {
    OpenCommand(path: "/Applications", notification: nil)
  }
}

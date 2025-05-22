import Foundation

struct WallpaperCommand: MetaDataProviding {
  var meta: Command.MetaData
  var source: Source
  var screens: [Screen]

  init(id: String = UUID().uuidString,
       name: String = "",
       notification: Command.Notification? = nil,
       source: Source,
       screens: [Screen]) {
    self.meta = Command.MetaData(id: id, name: name, isEnabled: true, notification: notification)
    self.source = source
    self.screens = screens
  }
}

import Foundation

struct WallpaperCommand: MetaDataProviding {
  var meta: Command.MetaData
  var kind: Kind
  var screens: [Screen]

  init(id: String = UUID().uuidString,
       name: String = "",
       notification: Command.Notification? = nil,
       kind: Kind,
       screens: [Screen]) {
    self.meta = Command.MetaData(id: id, name: name, isEnabled: true, notification: notification)
    self.kind = kind
    self.screens = screens
  }
}

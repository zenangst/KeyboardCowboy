import Apps
import Bonzai

extension Icon {
  init(_ app: Application) {
    self.init(bundleIdentifier: app.bundleIdentifier, path: app.path)
  }
}

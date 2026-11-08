import Apps
import Foundation

public extension Command {
  /// Persisted open-command payload. Paths are retained without normalization.
  struct Open: MetaDataProviding {
    public let application: Apps.Application?
    public var path: String
    public var meta: Metadata

    public init(application: Apps.Application? = nil, path: String, meta: Metadata = Metadata()) {
      self.application = application
      self.path = path
      self.meta = meta
    }

    public func copy() -> Open {
      Open(application: application, path: path, meta: meta.copy())
    }
  }
}

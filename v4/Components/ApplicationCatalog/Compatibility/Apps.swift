import ApplicationCatalog
import Foundation

public typealias Application = ApplicationCatalog.Application

public enum ApplicationController {
  public static func commonPaths() -> [URL] {
    ApplicationCatalog.defaultDirectories()
  }

  public static func load(_ additionalPaths: [URL] = []) async -> [Application] {
    await ApplicationCatalog.applications(additionalDirectories: additionalPaths)
  }
}

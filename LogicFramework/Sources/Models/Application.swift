import Foundation

public struct Application: Codable, Hashable {
  public let bundleIdentifier: String
  public let name: String
  public let path: String
}

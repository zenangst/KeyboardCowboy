import Foundation

public struct Workflow: Codable, Hashable {
  public let commands: [Command]
  public let name: String
}

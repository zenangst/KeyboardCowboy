import Foundation

public struct TypeCommand: Identifiable, Codable, Hashable {
  public let id: String
  public var name: String
  public var input: String

  public init(id: String = UUID().uuidString,
              name: String,
              input: String) {
    self.id = id
    self.name = name
    self.input = input
  }
}

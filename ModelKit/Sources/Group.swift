import Foundation

/// A group is a collection of `Workflow`s. Eligability is determined
/// by the collection of rules that the `Group` also holds reference to.
///
/// - Note: `[Rule]` are used to determine if a
///          collection of workflows are eligible to be invoked.
///          All rules have to return `true` for workflows to be
///          eligable for execution.
public struct Group: Identifiable, Codable, Hashable {
  public let id: String
  public let symbol: String
  public var name: String
  public var color: String
  public var rule: Rule?
  public var workflows: [Workflow]

  public init(id: String = UUID().uuidString,
              symbol: String = "folder",
              name: String,
              color: String = "#000",
              rule: Rule? = nil,
              workflows: [Workflow] = []) {
    self.id = id
    self.symbol = symbol
    self.name = name
    self.color = color
    self.rule = rule
    self.workflows = workflows
  }

  enum CodingKeys: String, CodingKey {
    case color
    case id
    case symbol
    case name
    case rule
    case workflows
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
    self.symbol = try container.decodeIfPresent(String.self, forKey: .symbol) ?? "folder"
    self.color = try container.decodeIfPresent(String.self, forKey: .color) ?? "#000"
    self.name = try container.decode(String.self, forKey: .name)
    self.rule = try container.decodeIfPresent(Rule.self, forKey: .rule)
    self.workflows = try container.decode([Workflow].self, forKey: .workflows)
  }
}

extension Group {
  static public func empty(id: String = UUID().uuidString) -> Group {
    Group(id: id, name: "Untitled group", color: "#000",
          workflows: [Workflow.empty(id: id)])
  }

  static public func droppedApplication(id: String = UUID().uuidString,
                                        _ application: Application) -> Group {
    Group(id: id,
          name: application.bundleName,
          color: "#000",
          rule: Rule(bundleIdentifiers: [application.bundleIdentifier],
                     days: []),
          workflows: [])
  }
}

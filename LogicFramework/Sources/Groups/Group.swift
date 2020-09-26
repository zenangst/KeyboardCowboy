import Foundation

/// A group is a collection of `Workflow`s. Eligability is determined
/// by the collection of rules that the `Group` also holds reference to.
///
/// - Note: `[Rule]` are used to determine if a
///          collection of workflows are eligible to be invoked.
///          All rules have to return `true` for workflows to be
///          eligable for execution.
public struct Group: Codable, Hashable {
  public let id: String
  public let name: String
  public let rule: Rule?
  public let workflows: [Workflow]

  public init(id: String = UUID().uuidString,
              name: String,
              rule: Rule? = nil,
              workflows: [Workflow] = []) {
    self.id = id
    self.name = name
    self.rule = rule
    self.workflows = workflows
  }

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case rule
    case workflows
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
    self.name = try container.decode(String.self, forKey: .name)
    self.rule = try container.decodeIfPresent(Rule.self, forKey: .rule)
    self.workflows = try container.decode([Workflow].self, forKey: .workflows)
  }
}

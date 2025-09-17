import Apps
import Foundation

/// A group is a collection of `Workflow`s. Eligability is determined
/// by the collection of rules that the `Group` also holds reference to.
///
/// - Note: `[Rule]` are used to determine if a
///          collection of workflows are eligible to be invoked.
///          All rules have to return `true` for workflows to be
///          eligable for execution.
struct WorkflowGroup: Identifiable, Equatable, Codable, Hashable, Sendable {
  private(set) var id: String
  var isDisabled: Bool
  var isEnabled: Bool { !isDisabled }
  var symbol: String
  var name: String
  var color: String
  var rule: Rule?
  var userModes: [UserMode] = []
  var workflows: [Workflow]

  init(id: String = UUID().uuidString,
       symbol: String = "folder",
       name: String,
       color: String = "#000",
       rule: Rule? = nil,
       userModes: [UserMode] = [],
       workflows: [Workflow] = [])
  {
    self.id = id
    self.symbol = symbol
    self.name = name
    self.color = color
    self.rule = rule
    self.userModes = userModes
    self.workflows = workflows
    isDisabled = false
  }

  func copy() -> Self {
    var clone = self
    clone.id = UUID().uuidString
    clone.workflows = workflows.map { $0.copy() }
    return clone
  }

  enum CodingKeys: String, CodingKey {
    case color
    case id
    case disabled
    case symbol
    case name
    case rule
    case userModes
    case workflows
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
    symbol = try container.decodeIfPresent(String.self, forKey: .symbol) ?? "folder"
    color = try container.decodeIfPresent(String.self, forKey: .color) ?? "#000"
    name = try container.decode(String.self, forKey: .name)
    rule = try container.decodeIfPresent(Rule.self, forKey: .rule)
    userModes = try container.decodeIfPresent([UserMode].self, forKey: .userModes) ?? []
    workflows = try container.decodeIfPresent([Workflow].self, forKey: .workflows) ?? []
    isDisabled = try container.decodeIfPresent(Bool.self, forKey: .disabled) ?? false
  }

  func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(color, forKey: .color)
    try container.encode(id, forKey: .id)
    try container.encode(symbol, forKey: .symbol)
    try container.encode(name, forKey: .name)
    try container.encodeIfPresent(rule, forKey: .rule)
    if !userModes.isEmpty {
      try container.encode(userModes, forKey: .userModes)
    }
    if !workflows.isEmpty {
      try container.encode(workflows, forKey: .workflows)
    }

    if isDisabled {
      try container.encode(isDisabled, forKey: .disabled)
    }
  }
}

extension WorkflowGroup {
  static func empty(id: String = UUID().uuidString) -> WorkflowGroup {
    WorkflowGroup(id: id, name: "Untitled group", color: "#000",
                  workflows: [])
  }

  static func droppedApplication(id: String = UUID().uuidString,
                                 _ application: Application) -> WorkflowGroup
  {
    WorkflowGroup(id: id,
                  name: application.displayName,
                  color: "#000",
                  rule: Rule(allowedBundleIdentifiers: [application.bundleIdentifier]),
                  workflows: [
                  ])
  }

  static func designTime() -> WorkflowGroup {
    let application = Application.finder()
    return WorkflowGroup(id: UUID().uuidString,
                         name: application.displayName,
                         color: "#6BD35F",
                         rule: Rule(allowedBundleIdentifiers: [
                           application.bundleIdentifier,
                           Application.music().bundleIdentifier,
                           Application.xcode().bundleIdentifier,
                         ]),
                         workflows: [
                           Workflow.designTime(nil),
                           Workflow.designTime(.application([.init(application: application)])),
                           Workflow.designTime(.keyboardShortcuts(.init(shortcuts: [
                             .init(key: "A"),
                             .init(key: "B"),
                             .init(key: "C"),
                           ]))),
                         ])
  }
}

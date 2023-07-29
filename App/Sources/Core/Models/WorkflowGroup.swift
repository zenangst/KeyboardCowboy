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
  var symbol: String
  var name: String
  var color: String
  var rule: Rule?
  var workflows: [Workflow]

  init(id: String = UUID().uuidString,
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

  func copy() -> Self {
    var clone = self
    clone.id = UUID().uuidString
    clone.name += " copy"
    clone.workflows = workflows.map { $0.copy(appendCopyToName: false) }
    return clone
  }

  enum CodingKeys: String, CodingKey {
    case color
    case id
    case symbol
    case name
    case rule
    case workflows
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
    self.symbol = try container.decodeIfPresent(String.self, forKey: .symbol) ?? "folder"
    self.color = try container.decodeIfPresent(String.self, forKey: .color) ?? "#000"
    self.name = try container.decode(String.self, forKey: .name)
    self.rule = try container.decodeIfPresent(Rule.self, forKey: .rule)
    self.workflows = try container.decodeIfPresent([Workflow].self, forKey: .workflows) ?? []
  }
}

extension WorkflowGroup {
  static func empty(id: String = UUID().uuidString) -> WorkflowGroup {
    WorkflowGroup(id: id, name: "Untitled group", color: "#000",
                  workflows: [])
  }

  static func droppedApplication(id: String = UUID().uuidString,
                                        _ application: Application) -> WorkflowGroup {
    WorkflowGroup(id: id,
          name: application.displayName,
          color: "#000",
          rule: Rule(bundleIdentifiers: [application.bundleIdentifier],
                     days: []),
          workflows: [
          ])
  }

  static func designTime() -> WorkflowGroup {
    let application = Application.finder()
    return WorkflowGroup(id: UUID().uuidString,
                         name: application.displayName,
                         color: "#6BD35F",
                         rule: Rule(bundleIdentifiers: [
                          application.bundleIdentifier,
                          Application.music().bundleIdentifier,
                          Application.xcode().bundleIdentifier,
                         ],
                                    days: []),
                         workflows: [
                          Workflow.designTime(nil),
                          Workflow.designTime(.application([.init(application: application)])),
                          Workflow.designTime(.keyboardShortcuts(.init(shortcuts: [
                            .init(key: "A", lhs: true),
                            .init(key: "B", lhs: false),
                            .init(key: "C", lhs: true)
                          ])))
                         ])
  }
}

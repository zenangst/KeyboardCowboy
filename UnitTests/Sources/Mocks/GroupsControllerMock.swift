import Foundation
import LogicFramework
import ModelKit

class GroupsControllerMock: GroupsControlling {
  typealias StateHandler = (State) -> Void
  enum State {
    case filterGroups(rule: Rule)
    case reloadGroups(groups: [Group])
    case group(identifier: String)
    case workflow(identifier: String)
    case keyboardShortcut(identifier: String)
  }

  weak var delegate: GroupsControllingDelegate?
  var groups = [Group]()
  var handler: StateHandler
  var group: Group?
  var workflow: Workflow?

  init(handler: @escaping StateHandler) {
    self.handler = handler
  }

  func filterGroups(using rule: Rule) -> [Group] {
    handler(.filterGroups(rule: rule))
    return groups
  }

  func reloadGroups(_ groups: [Group]) {
    handler(.reloadGroups(groups: groups))
  }

  func group(for workflow: Workflow) -> Group? {
    handler(.group(identifier: workflow.id))
    return group
  }
  func workflow(for command: Command) -> Workflow? {
    handler(.workflow(identifier: command.id))
    return workflow
  }

  func workflow(for keyboardShortcut: KeyboardShortcut) -> Workflow? {
    handler(.keyboardShortcut(identifier: keyboardShortcut.id))
    return workflow
  }
}

import Foundation
import LogicFramework

class GroupsControllerMock: GroupsControlling {
  typealias StateHandler = (State) -> Void
  enum State {
    case filterGroups(rule: Rule)
    case reloadGroups(groups: [Group])
    case groupContext(identifier: String)
    case workflowContext(identifier: String)
  }

  weak var delegate: GroupsControllingDelegate?
  var groups = [Group]()
  var handler: StateHandler
  var groupContext: GroupContext?
  var workflowContext: WorkflowContext?

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

  func groupContext(withIdentifier id: String) -> GroupContext? {
    handler(.groupContext(identifier: id))
    return groupContext
  }

  func workflowContext(workflowId: String) -> WorkflowContext? {
    handler(.workflowContext(identifier: workflowId))
    return workflowContext
  }
}

import Foundation
import LogicFramework
import ModelKit

class CoreControllerMock: CoreControlling, GroupsControllingDelegate {
  typealias StateHandler = (State) -> Void
  enum State {
    case respondTo(keyboardShortcut: KeyboardShortcut)
    case reloadContext
    case activate(workflows: [Workflow])
    case didReloadGroups(groups: [Group])
  }

  var groupsController: GroupsControlling
  var disableKeyboardShortcuts: Bool = false
  var groups = [Group]()
  var installedApplications = [Application]()
  var handler: StateHandler
  var workflows: [Workflow] = []

  init(groupsController: GroupsControlling, handler: @escaping StateHandler) {
    self.groupsController = groupsController
    self.handler = handler
  }

  func reloadContext() {
    handler(.reloadContext)
  }

  func activate(workflows: [Workflow]) {
    handler(.activate(workflows: workflows))
  }

  func respond(to keyboardShortcut: KeyboardShortcut) -> [Workflow] {
    handler(.respondTo(keyboardShortcut: keyboardShortcut))
    return workflows
  }

  // MARK: GroupsControllingDelegate

  func groupsController(_ controller: GroupsControlling, didReloadGroups groups: [Group]) {
    handler(.didReloadGroups(groups: groups))
  }
}

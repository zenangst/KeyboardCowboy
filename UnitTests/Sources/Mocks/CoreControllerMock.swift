import Foundation
import LogicFramework

class CoreControllerMock: CoreControlling, GroupsControllingDelegate {
  typealias StateHandler = (State) -> Void
  enum State {
    case respondTo(keyboardShortcut: KeyboardShortcut)
    case reloadContext
    case activate(keyboardShortcuts: Set<KeyboardShortcut>, rebindingWorkflows: [Workflow])
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

  func activate(_ keyboardShortcuts: Set<KeyboardShortcut>, rebindingWorkflows workflows: [Workflow]) {
    handler(.activate(keyboardShortcuts: keyboardShortcuts, rebindingWorkflows: workflows))
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

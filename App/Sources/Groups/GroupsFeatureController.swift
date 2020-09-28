import Foundation
import LogicFramework
import ViewKit

protocol GroupsFeatureControllerDelegate: AnyObject {
  func groupsFeatureController(_ controller: GroupsFeatureController, didReloadGroups groups: [Group])
}

class GroupsFeatureController: ViewController {
  weak var delegate: GroupsFeatureControllerDelegate?

  @Published var state = [GroupViewModel]()
  var applications = [Application]()
  let groupsController: GroupsControlling
  let mapper: GroupViewModelMapping

  init(groupsController: GroupsControlling,
       mapper: GroupViewModelMapping) {
    self.groupsController = groupsController
    self.mapper = mapper

    state = mapper.map(groupsController.groups)
  }

  func reload(_ groups: [Group]) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.groupsController.reloadGroups(groups)
      let viewModels = self.mapper.map(groups)
      self.state = viewModels
      self.delegate?.groupsFeatureController(self, didReloadGroups: groups)
    }
  }

  private func createNewGroup() {
    let newGroup = Group(name: "Untitled group")
    var groups = groupsController.groups
    groups.append(newGroup)
    reload(groups)
  }

  private func processUrl(_ url: URL) {
    guard let application = applications.first(where: { $0.path == url.path }) else {
      return
    }

    var groups = groupsController.groups
    let group = Group(id: UUID().uuidString, name: application.bundleName,
                      rule: Rule(bundleIdentifiers: [application.bundleIdentifier], days: []),
                      workflows: [])
    groups.append(group)
    reload(groups)
  }

  // MARK: ViewController

  func perform(_ action: GroupList.Action) {
    switch action {
    case .dropFile(let url):
      processUrl(url)
    case .newGroup:
      createNewGroup()
    }
  }
}

import Foundation
import LogicFramework
import ViewKit

protocol GroupsFeatureControllerDelegate: AnyObject {
  func groupsFeatureController(_ controller: GroupsFeatureController, didReloadGroups groups: [Group])
}

class GroupsFeatureController: ViewController {
  weak var delegate: GroupsFeatureControllerDelegate?

  @Published var state = [GroupViewModel]()
  let groupsController: GroupsControlling
  let mapper: GroupViewModelMapping

  init(groupsController: GroupsControlling,
       mapper: GroupViewModelMapping) {
    self.groupsController = groupsController
    self.mapper = mapper

    state = mapper.map(groupsController.groups)
  }

  func reload(_ groups: [Group]) {
    groupsController.reloadGroups(groups)
    let viewModels = mapper.map(groups)
    state = viewModels
    delegate?.groupsFeatureController(self, didReloadGroups: groups)
  }

  // MARK: ViewController

  func perform(_ action: GroupList.Action) {
    let newGroup = Group(name: "Untitled group")
    var groups = groupsController.groups
    groups.append(newGroup)
    reload(groups)
  }
}

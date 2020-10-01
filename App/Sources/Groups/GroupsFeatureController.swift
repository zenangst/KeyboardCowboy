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

  private func newGroup() {
    let newGroup = Group(name: "Untitled group", color: "#000")
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
                      color: "#000",
                      rule: Rule(bundleIdentifiers: [application.bundleIdentifier], days: []),
                      workflows: [])
    groups.append(group)
    reload(groups)
  }

  private func save(_ viewModel: GroupViewModel) {
    var groups = groupsController.groups
    guard let model = groups.first(where: { $0.id == viewModel.id }),
          let index = groups.firstIndex(of: model) else {
      return
    }

    let newModel = Group(id: model.id,
                         name: viewModel.name,
                         color: viewModel.color,
                         rule: model.rule,
                         workflows: model.workflows)
    groups[index] = newModel
    reload(groups)
  }

  private func delete(_ viewModel: GroupViewModel) {
    var groups = groupsController.groups
    guard let model = groups.first(where: { $0.id == viewModel.id }),
          let index = groups.firstIndex(of: model) else {
      return
    }

    groups.remove(at: index)
    reload(groups)
  }

  // MARK: ViewController

  func perform(_ action: GroupList.Action) {
    switch action {
    case .createGroup:
      newGroup()
    case .deleteGroup(let group):
      delete(group)
    case .updateGroup(let group):
      save(group)
    case .dropFile(let url):
      processUrl(url)
    }
  }
}

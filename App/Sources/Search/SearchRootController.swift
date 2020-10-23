import Foundation
import ModelKit
import LogicFramework
import ViewKit
import SwiftUI
import Combine

final class SearchRootController {
  @Published var state: ModelKit.SearchResults = .empty()
  let commandSearch: SearchCommandsController
  let groupSearch: SearchGroupsController
  let workflowSearch: SearchWorkflowController
  let groupsController: GroupsControlling
  var anyCancellables = [AnyCancellable]()

  init(groupsController: GroupsControlling,
       groupSearch: SearchGroupsController) {
    let workflowSearch = SearchWorkflowController(searchGroupController: groupSearch)
    self.groupSearch = groupSearch
    self.workflowSearch = workflowSearch
    self.commandSearch = SearchCommandsController(searchWorkflowController: workflowSearch)
    self.groupsController = groupsController

    Publishers.MergeMany(
      groupSearch.$state,
      workflowSearch.$state,
      commandSearch.$state
    ).sink(receiveValue: { [weak self] in
      guard let self = self else { return }

      var newState = self.state
      switch $0 {
      case .commands(let commands):
        newState.commands = commands
      case .workflows(let workflows):
        newState.workflows = workflows
      case .groups(let groups):
        newState.groups = groups
      }

      self.state = newState
    }).store(in: &anyCancellables)
  }

  func search(for query: String) {
    workflowSearch.query = query
    commandSearch.query = query

    var workingCopy = groupsController.groups
    var results = [ModelKit.Group]()

    results.append(contentsOf: searchForGroupByName(query, workingCopy: &workingCopy))
    results.append(contentsOf: searchForWorkflowByName(query, workingCopy: &workingCopy))
    results.append(contentsOf: searchForCommandByName(query, workingCopy: &workingCopy))

    groupSearch.state = .groups(results)
  }

  private func searchForGroupByName(_ query: String,
                                    workingCopy: inout [ModelKit.Group]) -> [ModelKit.Group] {
    var results = [ModelKit.Group]()
    var offsetCount: Int = 0
    for (offset, group) in workingCopy.enumerated() {
      if group.name.containsCaseSensitive(query) {
        results.append(workingCopy.remove(at: offset - offsetCount))
        offsetCount += 1
      }
    }
    return results
  }

  private func searchForWorkflowByName(_ query: String,
                                       workingCopy: inout [ModelKit.Group]) -> [ModelKit.Group] {
    var results = [ModelKit.Group]()
    var offsetCount: Int = 0
    for (offset, group) in workingCopy.enumerated() {
      if !group.workflows.filter({ $0.name.containsCaseSensitive(query) }).isEmpty {
        results.append(workingCopy.remove(at: offset - offsetCount))
        offsetCount += 1
      }
    }
    return results
  }

  private func searchForCommandByName(_ query: String,
                                      workingCopy: inout [ModelKit.Group]) -> [ModelKit.Group] {
    var results = [ModelKit.Group]()
    var offsetCount: Int = 0
    for (offset, group) in workingCopy.enumerated() {
      if !group.workflows
          .flatMap({ $0.commands })
          .filter({ $0.name.containsCaseSensitive(query) }).isEmpty {
        results.append(workingCopy.remove(at: offset - offsetCount))
        offsetCount += 1
      }
    }
    return results
  }
}

import Foundation
import ModelKit
import ViewKit
import SwiftUI
import Combine

class SearchWorkflowController: StateController {
  @Published var state = ModelKit.SearchResult.workflows([])
  let searchGroupController: SearchGroupsController
  var anyCancellables = [AnyCancellable]()
  var query: String = ""

  init(searchGroupController: SearchGroupsController) {
    self.searchGroupController = searchGroupController

    searchGroupController.$state.sink(receiveValue: { [weak self] results in
      guard let self = self,
            case .groups(let groups) = results else { return }
      let workflows = groups.flatMap({ self.searchForWorkflowByName(self.query, group: $0) })
      self.state = .workflows(workflows)
    }).store(in: &anyCancellables)
  }

  private func searchForWorkflowByName(_ query: String,
                                       group: ModelKit.Group) -> [ModelKit.Workflow] {
    group.workflows.filter {
      $0.name.containsCaseSensitive(query) ||
        !$0.commands.filter({ $0.name.containsCaseSensitive(query) }).isEmpty
    }
  }
}

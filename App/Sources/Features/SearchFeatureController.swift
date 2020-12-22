import Foundation
import ModelKit
import LogicFramework
import ViewKit
import SwiftUI
import Combine

final class SearchFeatureController: ViewController {
  @Published var state = ModelKit.SearchResults.empty()
  @AppStorage("groupSelection") var groupSelection: String?
  @AppStorage("workflowSelection") var workflowSelection: String?
  @AppStorage("workflowSelections") var workflowSelections: String?

  let groupController: GroupsControlling
  let searchController: SearchRootController
  var anyCancellables = [AnyCancellable]()

  init(groupController: GroupsControlling,
       searchController: SearchRootController,
       query: Binding<String>) {
    self.groupController = groupController
    self.searchController = searchController

    searchController.$state
      .dropFirst()
      .removeDuplicates()
      .sink(receiveValue: { [weak self] in
      guard let self = self else { return }
      self.state = $0
    }).store(in: &anyCancellables)
  }

  func perform(_ action: SearchResultsList.Action) {
    switch action {
    case .search(let query):
      searchController.search(for: query)
    case .selectCommand(let command):
      if let workflow = groupController.workflow(for: command),
         let group = groupController.group(for: workflow) {
        groupSelection = group.id
        workflowSelection = workflow.id
        workflowSelections = workflowSelection
      }
    case .selectWorkflow(let workflow):
      if let group = groupController.group(for: workflow) {
        groupSelection = group.id
        workflowSelection = workflow.id
        workflowSelections = workflowSelection
      }
    }
  }
}

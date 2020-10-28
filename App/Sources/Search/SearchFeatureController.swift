import Foundation
import ModelKit
import ViewKit
import SwiftUI
import Combine

final class SearchFeatureController: ViewController {
  @Published var state = ModelKit.SearchResults.empty()
  let searchController: SearchRootController
  var userSelection: UserSelection
  var anyCancellables = [AnyCancellable]()

  init(userSelection: UserSelection,
       searchController: SearchRootController,
       query: Binding<String>) {
    self.userSelection = userSelection
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
      userSelection.group = searchController.groupsController.groups
        .first(where: { ($0.workflows.first(where: { $0.commands.contains(command) }) != nil) == true })
      if let group = userSelection.group {
        userSelection.workflow = group.workflows.first(where: { $0.commands.contains(command) })
      }
    case .selectWorkflow(let workflow):
      userSelection.group = searchController.groupsController
        .groups.first(where: { $0.workflows.containsElement(workflow) })
      userSelection.workflow = workflow
    }
  }
}

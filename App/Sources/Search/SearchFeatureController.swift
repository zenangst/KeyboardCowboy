import Foundation
import ModelKit
import LogicFramework
import ViewKit
import SwiftUI
import Combine

final class SearchFeatureController: ViewController {
  @Published var state = ModelKit.SearchResults.empty()
  let groupController: GroupsControlling
  let userSelection: UserSelection
  let searchController: SearchRootController
  var anyCancellables = [AnyCancellable]()

  init(searchController: SearchRootController,
       groupController: GroupsControlling,
       query: Binding<String>,
       userSelection: UserSelection) {
    self.groupController = groupController
    self.searchController = searchController
    self.userSelection = userSelection

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
      if let workflow = groupController.workflow(for: command) {
        userSelection.group = groupController.group(for: workflow)
        userSelection.group = groupController.group(for: workflow)
      }
    case .selectWorkflow(let workflow):
      userSelection.group = groupController.group(for: workflow)
      userSelection.workflow = workflow
    }
  }
}

import Foundation
import ModelKit
import ViewKit
import SwiftUI
import Combine

final class SearchFeatureController: ViewController {
  @Published var state = ModelKit.SearchResults.empty()
  let searchController: SearchRootController
  var anyCancellables = [AnyCancellable]()

  init(searchController: SearchRootController, query: Binding<String>) {
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
      break
    case .selectWorkflow(let workflow):
      break
    }
  }
}

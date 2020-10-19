import ModelKit
import SwiftUI
import Combine

final class SearchPreviewController: ViewController {
  @Published var state: ModelKit.SearchResults

  init(state: ModelKit.SearchResults = .empty()) {
    self._state = Published(initialValue: state)
  }

  func perform(_ action: SearchResultsList.Action) {}
}

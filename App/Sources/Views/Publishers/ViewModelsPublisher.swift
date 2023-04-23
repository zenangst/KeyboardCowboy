import SwiftUI

final class ViewModelsPublisher<ViewModel>: ObservableObject where ViewModel: Hashable,
                                                                   ViewModel: Identifiable {
  @Published var data: [ViewModel] = [ViewModel]()
  @Published var selections = Set<ViewModel.ID>()

  init(_ data: [ViewModel] = [ViewModel]()) {
    _data = .init(initialValue: data)
  }

  convenience init(_ data: ViewModel...) {
    self.init(data)
  }

  convenience init(_ data: ViewModel) {
    self.init([data])
  }

  convenience init(_ data: () -> [ViewModel]) {
    self.init(data())
  }

  convenience init(_ data: () -> ViewModel) {
    self.init([data()])
  }

  @MainActor
  func publish(_ newData: [ViewModel]? = nil, selections newSelections: [ViewModel.ID]? = nil) {
    if let newSelections {
      self.selections = Set(newSelections)
    }
    if let newData {
      self.data = newData
    }
  }
}

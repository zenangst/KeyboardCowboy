import SwiftUI

final class ViewModelsPublisher<ViewModel>: ObservableObject where ViewModel: Hashable,
                                                                   ViewModel: Identifiable {
  @Published var models: [ViewModel] = [ViewModel]()
  @Published var selections = Set<ViewModel.ID>()

  init(_ models: [ViewModel] = [ViewModel]()) {
    _models = .init(initialValue: models)
  }

  convenience init(_ models: ViewModel...) {
    self.init(models)
  }

  convenience init(_ model: ViewModel) {
    self.init([model])
  }

  convenience init(_ models: () -> [ViewModel]) {
    self.init(models())
  }

  convenience init(_ models: () -> ViewModel) {
    self.init([models()])
  }

  @MainActor
  func publish(_ newModels: [ViewModel]? = nil, selections newSelections: [ViewModel.ID]? = nil) {
    if let newSelections {
      self.selections <- Set(newSelections)
    }
    if let newModels {
      self.models <- newModels
    }
  }
}

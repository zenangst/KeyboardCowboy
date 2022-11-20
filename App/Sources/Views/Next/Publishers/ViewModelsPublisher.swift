import SwiftUI

final class ViewModelsPublisher<ViewModel>: ObservableObject where ViewModel: Hashable, ViewModel: Identifiable {
  @Published var models: [ViewModel] = [ViewModel]()
  @Published var selections = Set<ViewModel>()

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
  func publish(_ newModels: [ViewModel]? = nil,
               selections newSelections: [ViewModel]? = nil,
               withAnimation animation: Animation? = nil) {
    if let animation {
      withAnimation(animation) {
        if let newSelections {
          self.selections = Set(newSelections)
        }
        if let newModels {
          self.models = newModels
        }
      }
    } else {
      if let newSelections {
        self.selections = Set(newSelections)
      }
      if let newModels {
        self.models = newModels
      }
    }
  }
}

import SwiftUI

final class ViewModelPublisher<ViewModel>: ObservableObject where ViewModel: Hashable, ViewModel: Identifiable {
  @Published var model: ViewModel

  init(_ model: ViewModel) {
    _model = .init(initialValue: model)
  }

  convenience init(_ model: () -> ViewModel) {
    self.init(model())
  }

  @MainActor
  func publish(_ newModel: ViewModel) {
    self.model = newModel
  }
}

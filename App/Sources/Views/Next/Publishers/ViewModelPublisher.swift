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
  func publish(_ newModel: ViewModel, withAnimation animation: Animation? = nil) {
    if let animation {
      withAnimation(animation) {
        self.model = newModel
      }
    } else {
      self.model = newModel
    }
  }
}

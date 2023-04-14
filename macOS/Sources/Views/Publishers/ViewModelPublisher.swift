import SwiftUI

@MainActor
final class ViewModelPublisher<ViewModel>: ObservableObject where ViewModel: Hashable,
                                                                  ViewModel: Identifiable {
  @Published var model: ViewModel

  nonisolated init(_ model: ViewModel) {
    _model = .init(initialValue: model)
  }

  nonisolated convenience init(_ model: () -> ViewModel) {
    self.init(model())
  }

  func publish(_ newModel: ViewModel) {
    self.model = newModel
  }
}

import SwiftUI

@MainActor
final class ViewModelPublisher<ViewModel>: ObservableObject, Sendable where ViewModel: Hashable,
                                                                            ViewModel: Identifiable {
  @Published var data: ViewModel

  init(_ data: ViewModel) {
    _data = .init(initialValue: data)
  }

  convenience init(_ data: () -> ViewModel) {
    self.init(data())
  }

  func publish(_ newModel: ViewModel) {
    self.data <- newModel
  }
}

import SwiftUI

@MainActor
final class ViewModelPublisher<ViewModel>: ObservableObject where ViewModel: Hashable,
                                                                  ViewModel: Identifiable {
  @Published var data: ViewModel

  nonisolated init(_ data: ViewModel) {
    _data = .init(initialValue: data)
  }

  nonisolated convenience init(_ data: () -> ViewModel) {
    self.init(data())
  }

  func publish(_ newModel: ViewModel) {
    self.data = newModel
  }
}

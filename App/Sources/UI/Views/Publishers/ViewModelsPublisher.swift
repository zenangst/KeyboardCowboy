import SwiftUI

@MainActor
final class ViewModelsPublisher<ViewModel>: ObservableObject where ViewModel: Hashable,
                                                                   ViewModel: Identifiable {
  @Published var data: [ViewModel] = [ViewModel]()

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

  func publish(_ newData: [ViewModel]? = nil) {
    if let newData {
      self.data = newData
    }
  }
}

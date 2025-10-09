import SwiftUI

@MainActor
final class ViewModelsPublisher<ViewModel>: ObservableObject, Sendable where ViewModel: Hashable,
  ViewModel: Identifiable,
  ViewModel: Sendable
{
  @Published var data: [ViewModel] = .init()

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

  func publish(_ newData: [ViewModel]) {
    data = newData
  }
}

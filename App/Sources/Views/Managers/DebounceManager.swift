import Combine
import Foundation

final class DebounceManager<T> {
  private var subscription: AnyCancellable?
  private let subject = PassthroughSubject<T, Never>()
  @Published var value: T

  init(_ initialValue: T, milliseconds: Int, onUpdate: @escaping (T) -> Void) {
    _value = .init(initialValue: initialValue)
    subscription = subject
      .debounce(for: .milliseconds(milliseconds), scheduler: DispatchQueue.main)
      .sink { onUpdate($0) }
  }

  func process(_ newValue: T) {
    subject.send(newValue)
  }
}

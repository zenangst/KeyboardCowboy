import Combine
import Foundation

final class DebounceManager<T> {
  private var subscription: AnyCancellable?
  private let subject = PassthroughSubject<T, Never>()
  private let onUpdate: (T) -> Void

  init(for stride:  DispatchQueue.SchedulerTimeType.Stride = .milliseconds(500),
       onUpdate: @escaping (T) -> Void) {
    self.onUpdate = onUpdate
    self.subscription = subject
      .debounce(for: stride, scheduler: DispatchQueue.main)
      .sink { onUpdate($0) }
  }

  func send(_ value: T) {
    subject.send(value)
  }
}

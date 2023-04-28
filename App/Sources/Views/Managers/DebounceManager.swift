import Combine
import Foundation

protocol DebounceSnapshot { }

final class DebounceManager<Snapshot: DebounceSnapshot> {
  private var subscription: AnyCancellable?
  private let subject = PassthroughSubject<Snapshot, Never>()
  @Published var snapshot: Snapshot

  init(_ initialValue: Snapshot, milliseconds: Int, onUpdate: @escaping (Snapshot) -> Void) {
    _snapshot = .init(initialValue: initialValue)
    subscription = subject
      .debounce(for: .milliseconds(milliseconds), scheduler: DispatchQueue.main)
      .sink { onUpdate($0) }
  }

  func process(_ snapshot: Snapshot) {
    subject.send(snapshot)
  }
}

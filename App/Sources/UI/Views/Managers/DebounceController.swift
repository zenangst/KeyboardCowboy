import Combine
import Foundation

protocol DebounceSnapshot: Equatable { }
extension String: DebounceSnapshot { }

final class DebounceController<Snapshot: DebounceSnapshot> {
  enum Kind {
    case keyRepeat
    case keyDown
  }

  private var subscription: AnyCancellable?
  private let kind: Kind
  private let subject = PassthroughSubject<Snapshot, Never>()
  private let onUpdate: (Snapshot) -> Void
  @Published var snapshot: Snapshot

  init(_ initialValue: Snapshot, kind: Kind = .keyRepeat, milliseconds: Int, onUpdate: @escaping (Snapshot) -> Void) {
    self._snapshot = .init(initialValue: initialValue)
    self.onUpdate = onUpdate
    self.kind = kind
    self.subscription = subject
      .debounce(for: .milliseconds(milliseconds), scheduler: DispatchQueue.main)
      .sink {
        onUpdate($0)
      }
  }

  func process(_ snapshot: Snapshot) {
    switch kind {
    case .keyDown:
      subject.send(snapshot)
      return
    case .keyRepeat:
      if LocalEventMonitor.shared.repeatingKeyDown {
        subject.send(snapshot)
        return
      }
    }

    onUpdate(snapshot)
  }
}

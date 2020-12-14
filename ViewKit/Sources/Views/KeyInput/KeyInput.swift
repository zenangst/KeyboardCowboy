import Combine
import SwiftUI

public typealias KeyInputSubject = PassthroughSubject<KeyEquivalent, Never>

public final class KeyInputSubjectWrapper: ObservableObject, Subject {
  public typealias Output = KeyInputSubject.Output
  public typealias Failure = KeyInputSubject.Failure

  public func send(_ value: Output) {
    objectWillChange.send(value)
  }

  public func send(completion: Subscribers.Completion<Failure>) {
    objectWillChange.send(completion: completion)
  }

  public func send(subscription: Subscription) {
    objectWillChange.send(subscription: subscription)
  }

  public typealias ObjectWillChangePublisher = KeyInputSubject
  public let objectWillChange: ObjectWillChangePublisher
  public init(subject: ObjectWillChangePublisher = .init()) {
    objectWillChange = subject
  }

  public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Failure,
                                              S.Input == Output {
    objectWillChange.receive(subscriber: subscriber)
  }
}

public func keyboardShortcut<Sender, Label>(
  _ key: KeyEquivalent,
  name: String,
  sender: Sender,
  modifiers: EventModifiers = .none,
  fallbackEvent: @escaping () -> Void,
  @ViewBuilder label: () -> Label
) -> some View where Label: View, Sender: Subject, Sender.Output == KeyEquivalent {
  Button(action: {
    sender.send(key)
    fallbackEvent()
  }, label: label)
    .keyboardShortcut(key, modifiers: modifiers)
}

public func keyboardShortcut<Sender>(
  _ key: KeyEquivalent,
  name: String,
  sender: Sender,
  modifiers: EventModifiers = .none,
  fallbackEvent: @escaping () -> Void
) -> some View where Sender: Subject, Sender.Output == KeyEquivalent {
  return AnyView(keyboardShortcut(key, name: name, sender: sender, modifiers: modifiers,
                                  fallbackEvent: fallbackEvent) {
    Text("\(name)")
  })
}

extension KeyEquivalent: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.character == rhs.character
  }
}

public extension EventModifiers {
  static let none = Self()
}

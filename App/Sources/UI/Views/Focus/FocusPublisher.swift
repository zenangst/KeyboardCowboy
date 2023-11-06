import Combine
import Foundation

enum Focused<Element>: Hashable where Element: Hashable,
                                      Element: Identifiable,
                                      Element: Equatable {
  case elementID(Element.ID)
}

final class FocusPublisherDebouncer<Element> where Element: Identifiable {
  private var subscription: AnyCancellable?
  private let subject = PassthroughSubject<Element.ID, Never>()
  private let onUpdate: (Element.ID) -> Void

  init(milliseconds: Int, onUpdate: @escaping (Element.ID) -> Void) {
    self.onUpdate = onUpdate
    self.subscription = subject
      .debounce(for: .milliseconds(milliseconds),
                scheduler: DispatchQueue.global(qos: .userInteractive))
      .receive(on: DispatchQueue.main)
      .sink { onUpdate($0) }
  }

  func process(_ snapshot: Element.ID) {
    subject.send(snapshot)
  }
}

@MainActor
final class FocusPublisher<Element>: ObservableObject where Element: Equatable,
                                                            Element: Hashable,
                                                            Element: Identifiable,
                                                            Element.ID: CustomStringConvertible {
  private lazy var debouncer: FocusPublisherDebouncer<Element> = .init(milliseconds: 50) { elementID in
    FocusableProxy<Element>.post(elementID)
    self.focus = .elementID(elementID)
  }

  private(set) var focus: Focused<Element> = .elementID("-1" as! Element.ID)
  {
    willSet {
      objectWillChange.send()
    }
  }

  func publish(_ elementID: Element.ID) {
    if NSEventController.shared.repeatingKeyDown {
      debouncer.process(elementID)
    } else {
      FocusableProxy<Element>.post(elementID)
      focus = .elementID(elementID)
    }
  }
}

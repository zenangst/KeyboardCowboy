import Foundation

enum Focused<Element>: Hashable where Element: Hashable,
                                      Element: Identifiable,
                                      Element: Equatable {
  case elementID(Element.ID)
}


final class FocusPublisher<Element>: ObservableObject where Element: Equatable,
                                                            Element: Hashable,
                                                            Element: Identifiable,
                                                            Element.ID: CustomStringConvertible {
  private(set) var focus: Focused<Element> = .elementID("-1" as! Element.ID)
  {
    willSet {
      objectWillChange.send()
    }
  }

  func publish(_ elementID: Element.ID) {
    FocusableProxy<Element>.post(elementID)
    focus = .elementID(elementID)
  }
}

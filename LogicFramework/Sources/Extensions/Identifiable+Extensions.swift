import Foundation

public enum IdentifiableCollectionError: Error {
  case unableToFindElement
}

public extension Array where Element: Identifiable {

  func containsElement(_ element: Element) -> Bool {
    first(where: { $0.id == element.id }) != nil ? true : false
  }

  mutating func add(_ element: Element, at index: Int = 0) {
    if index < count {
      self.insert(element, at: index)
    } else {
      self.append(element)
    }
  }

  mutating func replace(_ element: Element) throws {
    guard let index = self.firstIndex(where: { $0.id == element.id }) else {
      throw IdentifiableCollectionError.unableToFindElement
    }

    self[index] = element
  }

  mutating func remove(_ element: Element) throws {
    guard let index = self.firstIndex(where: { $0.id == element.id }) else {
      throw IdentifiableCollectionError.unableToFindElement
    }

    self.remove(at: index)
  }

  mutating func move(_ element: Element, to: Int) throws {
    guard let index = self.firstIndex(where: { $0.id == element.id }) else {
      throw IdentifiableCollectionError.unableToFindElement
    }

    _ = self.remove(at: index)

    if to > count {
      append(element)
    } else {
      insert(element, at: to)
    }
  }
}

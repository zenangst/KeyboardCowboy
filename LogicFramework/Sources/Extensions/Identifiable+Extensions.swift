import Foundation

public enum IdentifiableCollectionError: Error {
  case unableToFindElement
}

public extension Array where Element: Identifiable {

  func containsElement(_ element: Element?) -> Bool {
    guard let element = element else {
      return false
    }

    return first(where: { $0.id == element.id }) != nil ? true : false
  }

  /// Add an `Identifiable` element to the collection.
  /// The index is constrained to the collection size.
  /// If the index is less than `0`, it will be prepended at index `0`.
  /// And if the index is larger than the collection, the element will
  /// be appended.
  ///
  /// - Parameters:
  ///   - element: The `Identifiable` element subject that should be
  ///              added to the collection
  ///   - index: The desired index where the element should be inserted.
  mutating func add(_ element: Element, at index: Int? = nil) {
    if let index = index, index < count {
      self.insert(element, at: Swift.max(index, 0))
    } else {
      self.append(element)
    }
  }

  /// Replace an `Identifiable` element inside the collection.
  ///
  /// Uniqueness is determined by the `.id` of the `Identifiable` element.
  /// The function will locate the index using `.id` and then replace
  /// the existing element with the new one using subscripting.
  ///
  /// - Parameter element: The `Identifiable` element subject that should be
  ///                      used as the replacement.
  /// - Throws: The function will throw if the element does not exist inside
  ///           the collection.
  mutating func replace(_ element: Element) throws {
    guard let index = self.firstIndex(where: { $0.id == element.id }) else {
      throw IdentifiableCollectionError.unableToFindElement
    }

    self[index] = element
  }

  /// Remove an `Identifiable` element inside the collection.
  ///
  /// Uniqueness is determined by the `.id` of the `Identifiable` element.
  /// The function will locate the index using `.id` and then remove it
  /// by invoking `.remove(at:)`.
  ///
  /// - Parameter element: The `Identifiable` element subject that should be
  ///                      be removed from the collection
  /// - Parameter index: An optional index that will be used for removing the
  ///                    element. If `nil` is passed into the function, then
  ///                    it will try and determine the index using
  ///                    `firstIndex(where: { $0.id == element.id })`
  /// - Throws: The function will throw if the element does not exist inside
  ///           the collection.
  mutating func remove(_ element: Element, at index: Int? = nil) throws {
    var targetIndex: Int

    if let index = index {
      targetIndex = index
    } else if let index = self.firstIndex(where: { $0.id == element.id }) {
      targetIndex = index
    } else {
      throw IdentifiableCollectionError.unableToFindElement
    }

    self.remove(at: targetIndex)
  }

  /// Move an `Identifiable` element inside the collection to a new index.
  ///
  /// - Parameters:
  ///   - element: The `Identifiable` element subject that should be
  ///              moved to a new index inside the collection.
  ///   - to: The new index of the element
  /// - Throws: The function will throw if the element does not exist inside
  ///           the collection.
  mutating func move(_ element: Element, to: Int) throws {
    guard let previousIndex = self.firstIndex(where: { $0.id == element.id }) else {
      throw IdentifiableCollectionError.unableToFindElement
    }

    var newIndex = to
    if newIndex > previousIndex {
      newIndex -= 1
    }

    try self.remove(element, at: previousIndex)
    self.add(element, at: newIndex)
  }
}

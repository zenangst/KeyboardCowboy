import Foundation

// MARK: Experimental -
// Should probably measure performance and see what this would look like at
// call-sites.
extension MutableCollection where Element: Identifiable {
  subscript<T>(id: Element.ID, keyPath: WritableKeyPath<Element, T>) -> T {
    get {
      first(where: { $0.id == id })![keyPath: keyPath]
    }
    set {
      guard let offset = firstIndex(where: { $0.id == id }) else {
        assertionFailure("No workflow with id: \(id)")
        return
      }

      self[offset][keyPath: keyPath] = newValue
    }
  }

  mutating func replace(_ newElements: [Element]) {
    let old = self
    var new = self
    for element in newElements {
      guard let index = old.firstIndex(where: { $0.id == element.id }) else {
        continue
      }
      new[index] = element
    }
    self = new
  }

  mutating func edit<Value>(_ elementID: Element.ID, _ keyPath: WritableKeyPath<Element, Value>, _ update: @autoclosure () -> Value) {
    self[elementID, keyPath] = update()
  }

  mutating func edit<Value>(_ elementID: Element.ID, _ keyPath: WritableKeyPath<Element, Value>, _ update: (Value) -> Value) {
    let previousValue = self[elementID, keyPath]
    let newValue = update(previousValue)
    self[elementID, keyPath] = newValue
  }

  mutating func edit<Value: Equatable>(_ elementID: Element.ID, _ keyPath: WritableKeyPath<Element, Value>, _ update: (Value) -> Value) {
    let previousValue = self[elementID, keyPath]
    let newValue = update(previousValue)
    if previousValue != newValue {
      self[elementID, keyPath] = newValue
    }
  }
}

import Foundation
import Cocoa

@MainActor
final class SelectionManager<T>: ObservableObject where T: Identifiable,
                                                        T: Hashable {
  typealias StoreType = (Set<T.ID>) -> Void
  var lastSelection: T.ID?
  @Published var selections: Set<T.ID>

  private let store: StoreType

  init(_ selections: Set<T.ID> = [], initialSelection: Set<T.ID> = [], store: @escaping StoreType = { _ in }) {
    self.store = store
    if let lastSelection = Array(initialSelection).last {
      self.selections = [lastSelection]
      self.lastSelection = lastSelection
    } else {
      self.selections = selections
      self.lastSelection = nil
    }
  }

  @MainActor
  func publish(_ newSelections: Set<T.ID>) {
    self.selections = newSelections
    store(self.selections)
  }

  func handleOnTap(_ data: [T], element: T) {
    let copyOfSelections = selections
    if NSEvent.modifierFlags.contains(.shift) {
      selections = onShiftTap(data, elementID: element.id, selections: copyOfSelections)
    } else if NSEvent.modifierFlags.contains(.command) {
      selections = onCommandTap(element, selections: copyOfSelections)
    } else {
      selections = onTap(element)
    }
    store(self.selections)
  }

  private func onTap(_ element: T) -> Set<T.ID> {
    lastSelection = element.id
    return [element.id]
  }

  private func onCommandTap(_ element: T, selections: Set<T.ID>) -> Set<T.ID> {
    var newSelections = selections
    if selections.contains(element.id) {
      newSelections.remove(element.id)
    } else {
      newSelections.insert(element.id)
    }
    lastSelection = element.id
    return newSelections
  }

  private func onShiftTap(_ data: [T], elementID: T.ID, selections: Set<T.ID>) -> Set<T.ID> {
    var newSelections = selections

    if newSelections.contains(elementID) {
      newSelections.remove(elementID)
    } else {
      newSelections.insert(elementID)
    }

    guard let lastSelection else { return newSelections }

    guard var startIndex = data.firstIndex(where: { $0.id == lastSelection }),
          var endIndex = data.firstIndex(where: { $0.id == elementID }) else {
      return newSelections
    }

    if endIndex < startIndex {
      let copy = startIndex
      startIndex = endIndex
      endIndex = copy
    }

    data[startIndex...endIndex].forEach { element in
      if selections.contains(element.id) {
        if element.id != lastSelection {
          newSelections.remove(element.id)
        }
      } else {
        newSelections.insert(element.id)
      }
    }

    self.lastSelection = elementID

    return newSelections
  }
}

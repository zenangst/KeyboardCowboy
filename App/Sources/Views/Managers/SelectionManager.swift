import Foundation
import Cocoa

final class SelectionManager<T>: ObservableObject where T: Identifiable,
                                                        T: Hashable {
  var lastSelection: T.ID?
  @Published var selections: Set<T.ID>

  init(_ selections: Set<T.ID> = [],
       lastSelection: T.ID? = nil) {
    if let lastSelection {
      self.selections = [lastSelection]
      self.lastSelection = lastSelection
    } else {
      self.selections = selections
      self.lastSelection = lastSelection
    }
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
  }

  func onTap(_ element: T) -> Set<T.ID> {
    lastSelection = element.id
    return [element.id]
  }

  func onCommandTap(_ element: T, selections: Set<T.ID>) -> Set<T.ID> {
    var newSelections = selections
    if selections.contains(element.id) {
      newSelections.remove(element.id)
    } else {
      newSelections.insert(element.id)
    }
    lastSelection = element.id
    return newSelections
  }

  func onShiftTap(_ data: [T], elementID: T.ID, selections: Set<T.ID>) -> Set<T.ID> {
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

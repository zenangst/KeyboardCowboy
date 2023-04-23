import Foundation
import Cocoa

final class SelectionManager<T: Identifiable> {
  var lastSelection: T.ID?

  init(_ lastSelection: T.ID? = nil) {
    self.lastSelection = lastSelection
  }

  func handleOnTap(_ data: [T], element: T, selections: Set<T.ID>) -> Set<T.ID> {
    if NSEvent.modifierFlags.contains(.shift) {
      return onShiftTap(data, elementID: element.id, selections: selections)
    } else if NSEvent.modifierFlags.contains(.command) {
      return onCommandTap(element, selections: selections)
    } else {
      return onTap(element)
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

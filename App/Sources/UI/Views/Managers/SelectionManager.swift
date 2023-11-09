import Foundation
import Cocoa
import SwiftUI

@MainActor
final class SelectionManager<T>: ObservableObject where T: Identifiable,
                                                        T: Hashable,
                                                        T: Equatable {
  typealias StoreType = (Set<T.ID>) -> Void
  private(set) var lastSelection: T.ID?
  @Published var selections: Set<T.ID>
  @Published var selectedColor: Color = .accentColor

  private let store: StoreType

  init(_ selections: Set<T.ID> = [],
       initialSelection: Set<T.ID> = [],
       store: @escaping StoreType = { _ in }) {
    self.store = store
    if let firstSelection = Array(initialSelection).first {
      self.selections = [firstSelection]
      self.lastSelection = firstSelection
    } else {
      self.selections = selections
      self.lastSelection = nil
    }
  }

  func removeLastSelection() {
    self.lastSelection = nil
  }

  func setLastSelection(_ selection: T.ID) {
    self.lastSelection <- selection
    if self.selections.isEmpty {
      self.selections <- [selection]
    }
  }

  @MainActor
  func publish(_ newSelections: Set<T.ID>) {
    if self.selections != newSelections {
      self.selections = newSelections
    }
    store(self.selections)
  }

  func handle(_ direction: MoveCommandDirection,
              _ data: [T],
              proxy: ScrollViewProxy? = nil,
              vertical: Bool = true) -> T.ID? {
    switch direction {
    case .up:
      guard vertical else { return nil }
      return moveSelection(data, proxy: proxy) { max($0 - 1, 0) }
    case .down:
      guard vertical else { return nil }
      return moveSelection(data, proxy: proxy) { min($0 + 1, data.count - 1) }
    case .left:
      guard !vertical else { return nil }
      return moveSelection(data, proxy: proxy) { max($0 - 1, 0) }
    case .right:
      guard !vertical else { return nil }
      return moveSelection(data, proxy: proxy) { min($0 + 1, data.count - 1) }
    default:
      break
    }

    return nil
  }

  func handleOnTap(_ data: [T], element: T) {
    let copyOfSelections = selections
    var newSelections: Set<T.ID> = []
    if NSEvent.modifierFlags.contains(.shift) {
      newSelections = onShiftTap(data, elementID: element.id, selections: copyOfSelections)
    } else if NSEvent.modifierFlags.contains(.command) {
      newSelections = onCommandTap(element, selections: copyOfSelections)
    } else {
      newSelections = onTap(element)
    }
    store(newSelections)
    selections = newSelections
  }

  // MARK: Private methods

  private func moveSelection(_ data: [T],
                             proxy: ScrollViewProxy? = nil,
                             transform: (Int) -> Int) -> T.ID? {
    if let currentSelection = lastSelection ?? selections.first ?? data.first?.id,
       let currentIndex = data.firstIndex(where: { $0.id == currentSelection }) {
      let nextIndex = transform(currentIndex)

      let currentElementID = data[currentIndex].id
      let nextElementID = data[nextIndex].id

      var newSelections = selections

      if NSEvent.modifierFlags.contains(.shift) {
        if newSelections.contains(nextElementID) {
          newSelections.remove(currentElementID)
        } else {
          newSelections.insert(currentElementID)
        }
        newSelections.insert(nextElementID)
      } else {
        newSelections = [nextElementID]
      }

      selections = newSelections
      lastSelection = nextElementID

      defer {
        proxy?.scrollTo(nextElementID)
      }

      return nextElementID
    }

    return nil
  }

  private func onTap(_ element: T) -> Set<T.ID> {
    if lastSelection != element.id {
      lastSelection = element.id
    }
    return [element.id]
  }

  private func onCommandTap(_ element: T, selections: Set<T.ID>) -> Set<T.ID> {
    var newSelections = selections
    if selections.contains(element.id) {
      newSelections.remove(element.id)
    } else {
      newSelections.insert(element.id)
    }
    if lastSelection != element.id {
      lastSelection = element.id
    }
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

    if lastSelection != elementID {
      self.lastSelection = elementID
    }

    return newSelections
  }
}

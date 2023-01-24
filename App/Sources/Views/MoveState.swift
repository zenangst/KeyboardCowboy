import Foundation
enum MoveState<Element: Identifiable> {
  case inactive
  case dragging(draggedElementID: Element.ID, translation: CGSize)

  var element: Element.ID? {
    switch self {
    case .inactive:
      return nil
    case .dragging(let elementID, _):
      return elementID
    }
  }

  private func isDraggingElementID(_ elementID: Element.ID) -> Bool {
    if case .dragging(let draggedElementID, _) = self,
       draggedElementID == elementID {
      return true
    }
    return false
  }

  func scaleFactor(for elementID: Element.ID) -> Double { isDraggingElementID(elementID) ? 1.025 : 1 }

  func zIndex(for elementID: Element.ID) -> Double { isDraggingElementID(elementID) ? 1 : 0 }

  func offset(for elementID: Element.ID) -> CGSize {
    if case .dragging(_, let translation) = self,
       isDraggingElementID(elementID) {
      return translation
    }
    return .zero
  }
}

import SwiftUI

struct FillBackgroundView<Element>: View where Element: Hashable & Identifiable {
  @Environment(\.isFocused) var isFocused
  @ObservedObject var selectionManager: SelectionManager<Element>
  let id: Element.ID

  var body: some View {
    selectionManager.selectedColor
      .opacity(isFocused
               ? 0.5
               : selectionManager.selections.contains(id)
               ? 0.2
               : 0)
      .cornerRadius(4.0)
  }
}

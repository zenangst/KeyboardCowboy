import SwiftUI

struct GroupBackgroundView: View {
  @Environment(\.controlActiveState) var controlActiveState
  var isFocused: FocusState<AppFocus?>.Binding
  @ObservedObject var selectionManager: SelectionManager<GroupViewModel>
  let group: GroupViewModel

  var body: some View {
    Group {
      if selectionManager.selections.contains(group.id) {
        Color(nsColor:
                isFocused.wrappedValue == .groups
              ? .init(hex: group.color).blended(withFraction: 0.5, of: .black)!
              : .init(hex: group.color)
        )
      }
    }
    .cornerRadius(4, antialiased: true)
    .padding(.horizontal, 10)
    .grayscale(controlActiveState == .active ? 0.0 : 0.5)
    .opacity(isFocused.wrappedValue == .groups ? 1.0 : 0.1)
  }
}

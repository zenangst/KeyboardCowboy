import SwiftUI

struct ContentBackgroundView: View {
  @Environment(\.controlActiveState) var controlActiveState
  var focus: FocusState<AppFocus?>.Binding
  var data: [GroupViewModel]
  @ObservedObject var groupSelectionManager: SelectionManager<GroupViewModel>
  @ObservedObject var contentSelectionManager: SelectionManager<ContentViewModel>
  let workflow: ContentViewModel

  var body: some View {
    Group {
      if contentSelectionManager.selections.contains(workflow.id) {
        Color(nsColor: getColor())
      }
    }
    .cornerRadius(4, antialiased: true)
    .padding(.horizontal, 10)
    .grayscale(controlActiveState == .active ? 0.0 : 0.5)
    .opacity(focus.wrappedValue == .workflows ? 1 : 0.1)
    .animation(.default, value: groupSelectionManager.selections)
  }

  private func getColor() -> NSColor {
    let color: NSColor
    if let groupId = groupSelectionManager.selections.first,
       let group = data.first(where: { $0.id == groupId }),
       !group.color.isEmpty {
      color = .init(hex: group.color).blended(withFraction: 0.4, of: .black)!
    } else {
      color = .controlAccentColor
    }
    return color
  }
}

import SwiftUI

struct IconOverview: PreviewProvider {
  static let size: CGFloat = 96
  static var previews: some View {
    VStack {
      HStack {
        DockIconView(size: size)
        KeyboardIconView("M", size: size)
        MenuIconView(size: size)
        MouseIconView(size: size)
        MissionControlIconView(size: size)
      }

      HStack {
        ScriptIconView(size: size)
        TypingIconView(size: size)
        UIElementIconView(size: size)
        WindowManagementIconView(size: size)
        MinimizeAllIconView(size: size)
      }

      HStack {
        ActivateLastApplicationIconView(size: size)
        MoveFocusToWindowIconView(direction: .previous, scope: .activeApplication, size: size)
        MoveFocusToWindowIconView(direction: .next, scope: .activeApplication, size: size)
        MoveFocusToWindowIconView(direction: .previous, scope: .visibleWindows, size: size)
        MoveFocusToWindowIconView(direction: .next, scope: .visibleWindows, size: size)
      }

      HStack {
        MoveFocusToWindowIconView(direction: .previous, scope: .allWindows, size: size)
        MoveFocusToWindowIconView(direction: .next, scope: .allWindows, size: size)
      }
    }
    .padding()
    .background(Color(.windowBackgroundColor))
  }
}

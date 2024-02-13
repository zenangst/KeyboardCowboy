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
        ScriptIconView(size: size)
      }

      HStack {
        TypingIconView(size: size)
        UIElementIconView(size: size)
        WindowManagementIconView(size: size)
        MinimizeAllIconView(size: size)
        BugFixIconView(size: size)
        ImprovementIconView(size: size)
      }

      HStack {
        ActivateLastApplicationIconView(size: size)
        MacroIconView(.record, size: size)
        MacroIconView(.remove, size: size)
        MoveFocusToWindowIconView(direction: .previous, scope: .activeApplication, size: size)
        MoveFocusToWindowIconView(direction: .next, scope: .activeApplication, size: size)
        MoveFocusToWindowIconView(direction: .previous, scope: .visibleWindows, size: size)
      }

      HStack {
        MoveFocusToWindowIconView(direction: .next, scope: .visibleWindows, size: size)
        MoveFocusToWindowIconView(direction: .previous, scope: .allWindows, size: size)
        MoveFocusToWindowIconView(direction: .next, scope: .allWindows, size: size)
      }
    }
    .padding()
    .background(Color(.windowBackgroundColor))
  }
}

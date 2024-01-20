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
        MoveFocusToWindowIconView(direction: .next, scope: .allWindows, size: size)
      }
      HStack {
        ScriptIconView(size: size)
        TypingIconView(size: size)
        UIElementIconView(size: size)
        WindowManagementIconView(size: size)
      }
    }
    .padding()
    .background(Color(.windowBackgroundColor))
  }
}

import Bonzai
import SwiftUI

struct IconOverview: PreviewProvider {
  static let size: CGFloat = 96
  static var previews: some View {
    FlowLayout(itemSpacing: 8, lineSpacing: 8) {
      WindowManagementIconView(size: size)
      MenuIconView(size: size)
      MinimizeAllIconView(size: size)
      ActivateLastApplicationIconView(size: size)
      SnippetIconView(size: size)
      MoveFocusToWindowIconView(direction: .previous, scope: .allWindows, size: size)
      MoveFocusToWindowIconView(direction: .next, scope: .allWindows, size: size)
      MacroIconView(.remove, size: size)
      UIElementIconView(size: size)
      MouseIconView(size: size)
      BugFixIconView(size: size)
      MoveFocusToWindowIconView(direction: .previous, scope: .visibleWindows, size: size)
      MoveFocusToWindowIconView(direction: .next, scope: .visibleWindows, size: size)
      DockIconView(size: size)
      MissionControlIconView(size: size)
      MacroIconView(.record, size: size)
      MoveFocusToWindowIconView(direction: .previous, scope: .activeApplication, size: size)
      MoveFocusToWindowIconView(direction: .next, scope: .activeApplication, size: size)
      ScriptIconView(size: size)
      KeyboardIconView("M", size: size)
      ImprovementIconView(size: size)
    }
    .frame(maxWidth: 96 * 4 + 8 * 4)
    .padding(16)
    .background(Color(.windowBackgroundColor))
    .previewLayout(.sizeThatFits)
  }
}

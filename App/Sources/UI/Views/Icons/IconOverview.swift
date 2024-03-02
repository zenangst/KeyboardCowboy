import Bonzai
import SwiftUI

struct IconOverview: PreviewProvider {
  static let size: CGFloat = 96
  static let spacing: CGFloat = 16
  static var previews: some View {
    FlowLayout(itemSpacing: spacing, lineSpacing: spacing) {
      WindowManagementIconView(size: size)
      ActivateLastApplicationIconView(size: size)
      SnippetIconView(size: size)
      MoveFocusToWindowIconView(direction: .next, scope: .allWindows, size: size)
      MacroIconView(.remove, size: size)
      UIElementIconView(size: size)
      MouseIconView(size: size)
      BugFixIconView(size: size)
      MoveFocusToWindowIconView(direction: .previous, scope: .visibleWindows, size: size)
      MoveFocusToWindowIconView(direction: .next, scope: .visibleWindows, size: size)
      DockIconView(size: size)
      MacroIconView(.record, size: size)
      MoveFocusToWindowIconView(direction: .previous, scope: .activeApplication, size: size)
      MoveFocusToWindowIconView(direction: .next, scope: .activeApplication, size: size)
      GenericAppIconView(size: size)
      MissionControlIconView(size: size)
      UIImprovementIconView(size: size)
      MenuIconView(size: size)
      MinimizeAllIconView(size: size)
      UserModeIconView(size: size)
      MoveFocusToWindowIconView(direction: .previous, scope: .allWindows, size: size)
      ScriptIconView(size: size)
      KeyboardIconView("M", size: size)
      ImprovementIconView(size: size)
    }
    .frame(maxWidth: size * 5 + spacing * 5)
    .padding(spacing)
    .background(Color(.windowBackgroundColor))
    .previewLayout(.sizeThatFits)
  }
}

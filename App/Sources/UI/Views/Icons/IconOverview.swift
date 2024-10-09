import Bonzai
import SwiftUI

struct IconOverview: PreviewProvider {
  static let size: CGFloat = 96
  static let spacing: CGFloat = 16
  static var previews: some View {
    FlowLayout(itemSpacing: spacing, lineSpacing: spacing) {
      RepeatLastWorkflowIconView(size: size)
      SnippetIconView(size: size)
      TriggersIconView(size: size)
      HideAllIconView(size: size)
      WindowManagementIconView(size: size)
      ActivateLastApplicationIconView(size: size)
      RelativeFocusIconView(.up, size: size)
      MagicVarsIconView(size: size)
      MacroIconView(.remove, size: size)
      MoveFocusToWindowIconView(direction: .next, scope: .allWindows, size: size)
      WorkspaceIcon(size: size)
      WindowTilingIcon(kind: .arrangeLeftQuarters, size: size)
      AppFocusIcon(size: size)
      UIElementIconView(size: size)
      PrivacyIconView(size: size)
      EnvironmentIconView(size: size)
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
      TypingIconView(size: size)
      ScriptIconView(size: size)
      CommandLineIconView(size: size)
      KeyboardIconView("M", size: size)
      ImprovementIconView(size: size)
      ErrorIconView(size: size)
      WarningIconView(size: size)
    }
    .frame(maxWidth: size * 5 + spacing * 5)
    .padding(spacing)
    .background(Color(.windowBackgroundColor))
    .previewLayout(.sizeThatFits)
  }
}

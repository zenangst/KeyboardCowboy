import XCTest
import SwiftUI
@testable import Keyboard_Cowboy

final class AssetGeneratorTests: XCTestCase {
  static let sizes: [CGFloat] = [24, 48, 96, 128]

  @MainActor
  func test_generateIcons() throws {
    for size in Self.sizes {
      try AssetGenerator.generate(filename: "Icons/WindowManagementIconView", size: size, content: WindowManagementIconView(size: size))
      try AssetGenerator.generate(filename: "Icons/ActivateLastApplicationIconView", size: size, content: ActivateLastApplicationIconView(size: size))
      try AssetGenerator.generate(filename: "Icons/RelativeFocusIconView", size: size, content: RelativeFocusIconView(.up, size: size))
      try AssetGenerator.generate(filename: "Icons/SnippetIconView", size: size, content: SnippetIconView(size: size))
      try AssetGenerator.generate(filename: "Icons/MagicVarsIconView", size: size, content: MagicVarsIconView(size: size))
      try AssetGenerator.generate(filename: "Icons/MacroIconView", size: size, content: MacroIconView(.remove, size: size))
      try AssetGenerator.generate(filename: "Icons/MoveFocusToWindowIconView", size: size, content: MoveFocusToWindowIconView(direction: .next, scope: .allWindows, size: size))
      try AssetGenerator.generate(filename: "Icons/UserModeIconView", size: size, content: UserModeIconView(size: size))
      try AssetGenerator.generate(filename: "Icons/UIElementIconView", size: size, content: UIElementIconView(size: size))
      try AssetGenerator.generate(filename: "Icons/EnvironmentIconView", size: size, content: EnvironmentIconView(size: size))
      try AssetGenerator.generate(filename: "Icons/MouseIconView", size: size, content: MouseIconView(size: size))
      try AssetGenerator.generate(filename: "Icons/BugFixIconView", size: size, content: BugFixIconView(size: size))
      try AssetGenerator.generate(filename: "Icons/MoveFocusToWindowIconView", size: size, content: MoveFocusToWindowIconView(direction: .previous, scope: .visibleWindows, size: size))
      try AssetGenerator.generate(filename: "Icons/MoveFocusToWindowIconView", size: size, content: MoveFocusToWindowIconView(direction: .next, scope: .visibleWindows, size: size))
      try AssetGenerator.generate(filename: "Icons/DockIconView", size: size, content: DockIconView(size: size))
      try AssetGenerator.generate(filename: "Icons/MacroIconView", size: size, content: MacroIconView(.record, size: size))
      try AssetGenerator.generate(filename: "Icons/MoveFocusToWindowIconView", size: size, content: MoveFocusToWindowIconView(direction: .previous, scope: .activeApplication, size: size))
      try AssetGenerator.generate(filename: "Icons/MoveFocusToWindowIconView", size: size, content: MoveFocusToWindowIconView(direction: .next, scope: .activeApplication, size: size))
      try AssetGenerator.generate(filename: "Icons/GenericAppIconView", size: size, content: GenericAppIconView(size: size))
      try AssetGenerator.generate(filename: "Icons/MissionControlIconView", size: size, content: MissionControlIconView(size: size))
      try AssetGenerator.generate(filename: "Icons/UIImprovementIconView", size: size, content: UIImprovementIconView(size: size))
      try AssetGenerator.generate(filename: "Icons/MenuIconView", size: size, content: MenuIconView(size: size))
      try AssetGenerator.generate(filename: "Icons/MinimizeAllIconView", size: size, content: MinimizeAllIconView(size: size))
      try AssetGenerator.generate(filename: "Icons/UserModeIconView", size: size, content: UserModeIconView(size: size))
      try AssetGenerator.generate(filename: "Icons/MoveFocusToWindowIconView", size: size, content: MoveFocusToWindowIconView(direction: .previous, scope: .allWindows, size: size))
      try AssetGenerator.generate(filename: "Icons/TypingIconView", size: size, content: TypingIconView(size: size))
      try AssetGenerator.generate(filename: "Icons/ScriptIconView", size: size, content: ScriptIconView(size: size))
      try AssetGenerator.generate(filename: "Icons/CommandLineIconView", size: size, content: CommandLineIconView(size: size))
      try AssetGenerator.generate(filename: "Icons/KeyboardIconView", size: size, content: KeyboardIconView("M", size: size))
      try AssetGenerator.generate(filename: "Icons/ImprovementIconView", size: size, content: ImprovementIconView(size: size))
      try AssetGenerator.generate(filename: "Icons/ErrorIconView", size: size, content: ErrorIconView(size: size))
      try AssetGenerator.generate(filename: "Icons/WindowManagementIconView", size: size, content: WarningIconView(size: size))
      try AssetGenerator.generate(filename: "Icons/TriggersIconView", size: size, content: TriggersIconView(size: size))
    }
  }

  func test_generateWebAssets() {
    
  }
}

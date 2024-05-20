import XCTest
import SwiftUI
@testable import Keyboard_Cowboy

final class AssetGeneratorTests: XCTestCase {
  static let sizes: [CGSize] = [
    CGSize(width: 24, height: 24),
    CGSize(width: 48, height: 48),
    CGSize(width: 96, height: 96),
    CGSize(width: 128, height: 128)
  ]

  @MainActor
  func test_generateIcons() throws {
    for size in Self.sizes {
      try AssetGenerator.generate(filename: "Icons/WindowManagementIconView", size: size, content: WindowManagementIconView(size: size.width))
      try AssetGenerator.generate(filename: "Icons/ActivateLastApplicationIconView", size: size, content: ActivateLastApplicationIconView(size: size.width))
      try AssetGenerator.generate(filename: "Icons/RelativeFocusIconView", size: size, content: RelativeFocusIconView(.up, size: size.width))
      try AssetGenerator.generate(filename: "Icons/SnippetIconView", size: size, content: SnippetIconView(size: size.width))
      try AssetGenerator.generate(filename: "Icons/MagicVarsIconView", size: size, content: MagicVarsIconView(size: size.width))
      try AssetGenerator.generate(filename: "Icons/MacroIconView", size: size, content: MacroIconView(.remove, size: size.width))
      try AssetGenerator.generate(filename: "Icons/MoveFocusToWindowIconView", size: size, content: MoveFocusToWindowIconView(direction: .next, scope: .allWindows, size: size.width))
      try AssetGenerator.generate(filename: "Icons/UserModeIconView", size: size, content: UserModeIconView(size: size.width))
      try AssetGenerator.generate(filename: "Icons/UIElementIconView", size: size, content: UIElementIconView(size: size.width))
      try AssetGenerator.generate(filename: "Icons/EnvironmentIconView", size: size, content: EnvironmentIconView(size: size.width))
      try AssetGenerator.generate(filename: "Icons/MouseIconView", size: size, content: MouseIconView(size: size.width))
      try AssetGenerator.generate(filename: "Icons/BugFixIconView", size: size, content: BugFixIconView(size: size.width))
      try AssetGenerator.generate(filename: "Icons/MoveFocusToWindowIconView", size: size, content: MoveFocusToWindowIconView(direction: .previous, scope: .visibleWindows, size: size.width))
      try AssetGenerator.generate(filename: "Icons/MoveFocusToWindowIconView", size: size, content: MoveFocusToWindowIconView(direction: .next, scope: .visibleWindows, size: size.width))
      try AssetGenerator.generate(filename: "Icons/DockIconView", size: size, content: DockIconView(size: size.width))
      try AssetGenerator.generate(filename: "Icons/MacroIconView", size: size, content: MacroIconView(.record, size: size.width))
      try AssetGenerator.generate(filename: "Icons/MoveFocusToWindowIconView", size: size, content: MoveFocusToWindowIconView(direction: .previous, scope: .activeApplication, size: size.width))
      try AssetGenerator.generate(filename: "Icons/MoveFocusToWindowIconView", size: size, content: MoveFocusToWindowIconView(direction: .next, scope: .activeApplication, size: size.width))
      try AssetGenerator.generate(filename: "Icons/GenericAppIconView", size: size, content: GenericAppIconView(size: size.width))
      try AssetGenerator.generate(filename: "Icons/MissionControlIconView", size: size, content: MissionControlIconView(size: size.width))
      try AssetGenerator.generate(filename: "Icons/UIImprovementIconView", size: size, content: UIImprovementIconView(size: size.width))
      try AssetGenerator.generate(filename: "Icons/MenuIconView", size: size, content: MenuIconView(size: size.width))
      try AssetGenerator.generate(filename: "Icons/MinimizeAllIconView", size: size, content: MinimizeAllIconView(size: size.width))
      try AssetGenerator.generate(filename: "Icons/UserModeIconView", size: size, content: UserModeIconView(size: size.width))
      try AssetGenerator.generate(filename: "Icons/MoveFocusToWindowIconView", size: size, content: MoveFocusToWindowIconView(direction: .previous, scope: .allWindows, size: size.width))
      try AssetGenerator.generate(filename: "Icons/TypingIconView", size: size, content: TypingIconView(size: size.width))
      try AssetGenerator.generate(filename: "Icons/ScriptIconView", size: size, content: ScriptIconView(size: size.width))
      try AssetGenerator.generate(filename: "Icons/CommandLineIconView", size: size, content: CommandLineIconView(size: size.width))
      try AssetGenerator.generate(filename: "Icons/KeyboardIconView", size: size, content: KeyboardIconView("M", size: size.width))
      try AssetGenerator.generate(filename: "Icons/ImprovementIconView", size: size, content: ImprovementIconView(size: size.width))
      try AssetGenerator.generate(filename: "Icons/ErrorIconView", size: size, content: ErrorIconView(size: size.width))
      try AssetGenerator.generate(filename: "Icons/WindowManagementIconView", size: size, content: WarningIconView(size: size.width))
      try AssetGenerator.generate(filename: "Icons/TriggersIconView", size: size, content: TriggersIconView(size: size.width))
      try AssetGenerator.generate(filename: "Icons/PrivacyIconView", size: size, content: PrivacyIconView(size: size.width))
    }
  }

  @MainActor 
  func test_generateBento() throws {
    try AssetGenerator.generate(filename: "bento", useIntrinsicContentSize: true, size: CGSize(width: 1024, height: 768), content: PromoView())
  }

  func test_generateWebAssets() {
    
  }
}

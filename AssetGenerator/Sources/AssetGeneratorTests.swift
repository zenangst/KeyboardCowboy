import Apps
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
  func test_generateIcons() async throws {
    for size in Self.sizes {
      try await AssetGenerator.generate(filename: "Icons/WindowManagementIconView_\(Int(size.width))", size: size, content: WindowManagementIconView(size: size.width))
      try await AssetGenerator.generate(filename: "Icons/ActivateLastApplicationIconView_\(Int(size.width))", size: size, content: ActivateLastApplicationIconView(size: size.width))
      try await AssetGenerator.generate(filename: "Icons/RelativeFocusIconView_\(Int(size.width))", size: size, content: RelativeFocusIconView(.up, size: size.width))
      try await AssetGenerator.generate(filename: "Icons/SnippetIconView_\(Int(size.width))", size: size, content: SnippetIconView(size: size.width))
      try await AssetGenerator.generate(filename: "Icons/MagicVarsIconView_\(Int(size.width))", size: size, content: MagicVarsIconView(size: size.width))
      try await AssetGenerator.generate(filename: "Icons/MacroIconView_\(Int(size.width))", size: size, content: MacroIconView(.remove, size: size.width))
      try await AssetGenerator.generate(filename: "Icons/MoveFocusToWindowIconView_\(Int(size.width))", size: size, content: MoveFocusToWindowIconView(direction: .next, scope: .allWindows, size: size.width))
      try await AssetGenerator.generate(filename: "Icons/UserModeIconView_\(Int(size.width))", size: size, content: UserModeIconView(size: size.width))
      try await AssetGenerator.generate(filename: "Icons/UIElementIconView_\(Int(size.width))", size: size, content: UIElementIconView(size: size.width))
      try await AssetGenerator.generate(filename: "Icons/EnvironmentIconView_\(Int(size.width))", size: size, content: EnvironmentIconView(size: size.width))
      try await AssetGenerator.generate(filename: "Icons/MouseIconView_\(Int(size.width))", size: size, content: MouseIconView(size: size.width))
      try await AssetGenerator.generate(filename: "Icons/BugFixIconView_\(Int(size.width))", size: size, content: BugFixIconView(size: size.width))
      try await AssetGenerator.generate(filename: "Icons/MoveFocusToWindowIconView_\(Int(size.width))", size: size, content: MoveFocusToWindowIconView(direction: .previous, scope: .visibleWindows, size: size.width))
      try await AssetGenerator.generate(filename: "Icons/MoveFocusToWindowIconView_\(Int(size.width))", size: size, content: MoveFocusToWindowIconView(direction: .next, scope: .visibleWindows, size: size.width))
      try await AssetGenerator.generate(filename: "Icons/DockIconView_\(Int(size.width))", size: size, content: DockIconView(size: size.width))
      try await AssetGenerator.generate(filename: "Icons/MacroIconView_\(Int(size.width))", size: size, content: MacroIconView(.record, size: size.width))
      try await AssetGenerator.generate(filename: "Icons/MoveFocusToWindowIconView_\(Int(size.width))", size: size, content: MoveFocusToWindowIconView(direction: .previous, scope: .activeApplication, size: size.width))
      try await AssetGenerator.generate(filename: "Icons/MoveFocusToWindowIconView_\(Int(size.width))", size: size, content: MoveFocusToWindowIconView(direction: .next, scope: .activeApplication, size: size.width))
      try await AssetGenerator.generate(filename: "Icons/GenericAppIconView_\(Int(size.width))", size: size, content: GenericAppIconView(size: size.width))
      try await AssetGenerator.generate(filename: "Icons/MissionControlIconView_\(Int(size.width))", size: size, content: MissionControlIconView(size: size.width))
      try await AssetGenerator.generate(filename: "Icons/UIImprovementIconView_\(Int(size.width))", size: size, content: UIImprovementIconView(size: size.width))
      try await AssetGenerator.generate(filename: "Icons/MenuIconView_\(Int(size.width))", size: size, content: MenuIconView(size: size.width))
      try await AssetGenerator.generate(filename: "Icons/MinimizeAllIconView_\(Int(size.width))", size: size, content: MinimizeAllIconView(size: size.width))
      try await AssetGenerator.generate(filename: "Icons/UserModeIconView_\(Int(size.width))", size: size, content: UserModeIconView(size: size.width))
      try await AssetGenerator.generate(filename: "Icons/MoveFocusToWindowIconView_\(Int(size.width))", size: size, content: MoveFocusToWindowIconView(direction: .previous, scope: .allWindows, size: size.width))
      try await AssetGenerator.generate(filename: "Icons/TypingIconView_\(Int(size.width))", size: size, content: TypingIconView(size: size.width))
      try await AssetGenerator.generate(filename: "Icons/ScriptIconView_\(Int(size.width))", size: size, content: ScriptIconView(size: size.width))
      try await AssetGenerator.generate(filename: "Icons/CommandLineIconView_\(Int(size.width))", size: size, content: CommandLineIconView(size: size.width))
      try await AssetGenerator.generate(filename: "Icons/KeyboardIconView_\(Int(size.width))", size: size, content: KeyboardIconView("M", size: size.width))
      try await AssetGenerator.generate(filename: "Icons/ImprovementIconView_\(Int(size.width))", size: size, content: ImprovementIconView(size: size.width))
      try await AssetGenerator.generate(filename: "Icons/ErrorIconView_\(Int(size.width))", size: size, content: ErrorIconView(size: size.width))
      try await AssetGenerator.generate(filename: "Icons/WindowManagementIconView_\(Int(size.width))", size: size, content: WarningIconView(size: size.width))
      try await AssetGenerator.generate(filename: "Icons/TriggersIconView_\(Int(size.width))", size: size, content: TriggersIconView(size: size.width))
      try await AssetGenerator.generate(filename: "Icons/PrivacyIconView_\(Int(size.width))", size: size, content: PrivacyIconView(size: size.width))
    }
  }

  @MainActor func test_generateWikiAssets() async throws {
    let iconSize = CGSize(width: 24, height: 24)

    try await generatePromoImage()
    try await generateIcons(iconSize)
    try await generateCommandsViews()
  }

  @MainActor private func generatePromoImage() async throws {
    // Promo image
    try await AssetGenerator.generate(filename: "Wiki/Home/Bento", useIntrinsicContentSize: true, size: CGSize(width: 1024, height: 768), content: PromoView())
  }

  @MainActor private func generateIcons(_ iconSize: CGSize) async throws {
    // Icons
    try await AssetGenerator.generate(filename: "Wiki/Icons/AppFocus", size: iconSize, content: AppFocusIcon(size: iconSize.width))
    try await AssetGenerator.generate(filename: "Wiki/Icons/Workspaces", size: iconSize, content: WorkspaceIcon(size: iconSize.width))
    try await AssetGenerator.generate(filename: "Wiki/Icons/AppPeek", size: iconSize, content: AppPeekIcon(size: iconSize.width))
    try await AssetGenerator.generate(filename: "Wiki/Icons/WindowTiling", size: iconSize, content: WindowTilingIcon(kind: .arrangeLeftQuarters, size: iconSize.width))

    try await AssetGenerator.generate(filename: "Wiki/Triggers/GenericAppIconView", size: iconSize, content: GenericAppIconView(size: iconSize.width))
    try await AssetGenerator.generate(filename: "Wiki/Triggers/TriggersIconView", size: iconSize, content: TriggersIconView(size: iconSize.width))
    try await AssetGenerator.generate(filename: "Wiki/Triggers/KeyboardIconView", size: iconSize, content: KeyboardIconView("M", size: iconSize.width))
  }

  @MainActor private func generateCommandsViews() async throws {
    await ApplicationStore.shared.load()
    try await Task.sleep(for: .milliseconds(500))
    let iconSize = CGSize(width: 24, height: 24)

    do {
      let content = generateCommandView(name: "Open Xcode") { meta in
        let xcode = findApplication("Xcode")
        return ApplicationCommandView(
          .init(name: "Open Xcode", namePlaceholder: "", icon: .some(.init(bundleIdentifier: xcode.bundleIdentifier, path: xcode.path))),
          model: CommandViewModel.Kind.ApplicationModel(
            id: UUID().uuidString,
            action: "Open",
            inBackground: false,
            hideWhenRunning: false,
            ifNotRunning: false,
            addToStage: false,
            waitForAppToLaunch: false
          ), iconSize: iconSize)
          }
      try await AssetGenerator.generate(filename: "Wiki/Commands/Application", useIntrinsicContentSize: true, size: iconSize, content: content)
    }

    do {
      let content = generateCommandView(name: "App Focus") { meta in
        BundledCommandView(
          meta,
          model: CommandViewModel.Kind.BundledModel(
            id: UUID().uuidString,
            name: meta.name,
            kind: .appFocus(
              .init(application: findApplication("Xcode"), tiling: .arrangeLeftQuarters, hideOtherApps: false, createNewWindow: true)
            )
          ),
          iconSize: iconSize
        )
      }

      try await AssetGenerator.generate(filename: "Wiki/Commands/AppFocus", useIntrinsicContentSize: true, size: iconSize, content: content)
    }

    do {
      let content = generateCommandView(name: "Workspace") { meta in
        BundledCommandView(
          meta,
          model: CommandViewModel.Kind.BundledModel(id: UUID().uuidString, name: meta.name, kind: .workspace(.init(applications: [
            findApplication("Xcode"),
            findApplication("GitHub"),
            findApplication("Ghostty"),
          ], hideOtherApps: true))),
          iconSize: iconSize
        )
      }

      try await AssetGenerator.generate(filename: "Wiki/Commands/Workspace", useIntrinsicContentSize: true, size: iconSize, content: content)
    }


    do {
      let content = generateCommandView(name: "WindowTidy") { meta in
        BundledCommandView(
          meta,
          model: CommandViewModel.Kind.BundledModel(id: UUID().uuidString, name: meta.name, kind: .tidy(.init(rules: [
            .init(application: findApplication("Xcode"), tiling: .left),
            .init(application: findApplication("GitHub"), tiling: .topRight),
            .init(application: findApplication("Ghostty"), tiling: .bottomRight),
          ]))),
          iconSize: iconSize
        )
      }

      try await AssetGenerator.generate(filename: "Wiki/Commands/WindowTidy", useIntrinsicContentSize: true, size: iconSize, content: content)
    }
  }

  @MainActor func generateCommandView<Content>(name: String, content: (CommandViewModel.MetaData) -> Content) -> some View where Content: View {
    let content = content(CommandViewModel.MetaData(name: name, namePlaceholder: ""))
      .frame(minWidth: 500)
      .padding()
      .designTime()
      .environmentObject(ViewModelPublisher(DetailViewModel.CommandsInfo(id: UUID().uuidString, commands: [], execution: .serial)))
    return content
  }

  @MainActor func findApplication(_ name: String) -> Application {
    let app = ApplicationStore.shared.applications.first(where: { $0.displayName == name })
    return app!
  }
}

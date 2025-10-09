import Apps
import Bonzai
@testable import Keyboard_Cowboy
import SwiftUI
import XCTest

final class AssetGeneratorTests: XCTestCase {
  static let sizes: [CGSize] = [
    CGSize(width: 24, height: 24),
    CGSize(width: 48, height: 48),
    CGSize(width: 96, height: 96),
    CGSize(width: 128, height: 128),
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
    try await generateGroups()
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

  @MainActor private func generateGroups() async throws {
    try await AssetGenerator.generate(filename: "Wiki/Groups/GroupWindow", useIntrinsicContentSize: true, size: .zero) {
      let userMode = UserMode(id: UUID().uuidString, name: "vim mode", isEnabled: true)
      let publisher = ConfigurationPublisher(.init(id: UUID().uuidString, name: "", selected: true, userModes: [userMode]))
      let group = WorkflowGroup(
        name: "Xcode",
        color: "#3984F7",
        rule: Rule(allowedBundleIdentifiers: ["com.apple.dt.Xcode"]),
        userModes: [userMode],
      )
      return EditWorfklowGroupView(applicationStore: ApplicationStore.shared, group: group, action: { _ in })
        .environmentObject(publisher)
        .background()
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .background {
          Color.black
            .padding(30)
            .shadow(color: .black.opacity(0.5), radius: 10, y: -45)
        }
        .padding(50)
    }
  }

  @MainActor private func generateCommandsViews() async throws {
    await ApplicationStore.shared.load()
    try await Task.sleep(for: .milliseconds(500))
    let iconSize = CGSize(width: 24, height: 24)

    try await commandAsset("ApplicationCommand") {
      generateCommandView(name: "Open Xcode") { _ in
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
            waitForAppToLaunch: false,
          ), iconSize: iconSize,
        )
      }
    }

    try await commandAsset("AppFocusCommand") {
      generateCommandView(name: "App Focus") { meta in
        BundledCommandView(
          meta,
          model: CommandViewModel.Kind.BundledModel(
            id: UUID().uuidString,
            name: meta.name,
            kind: .appFocus(
              .init(application: findApplication("Xcode"), tiling: .arrangeLeftQuarters, hideOtherApps: false, createNewWindow: true),
            ),
          ),
          iconSize: iconSize,
        )
      }
    }

    try await commandAsset("WorkspacesCommand") {
      generateCommandView(name: "Workspace") { meta in
        BundledCommandView(
          meta,
          model: CommandViewModel.Kind.BundledModel(id: UUID().uuidString, name: meta.name, kind: .workspace(.init(applications: [
            findApplication("Xcode"),
            findApplication("GitHub"),
            findApplication("Ghostty"),
          ], tiling: .arrangeLeftQuarters, hideOtherApps: true))),
          iconSize: iconSize,
        )
      }
    }

    try await commandAsset("WindowTidyCommand") {
      generateCommandView(name: "WindowTidy") { meta in
        BundledCommandView(
          meta,
          model: CommandViewModel.Kind.BundledModel(id: UUID().uuidString, name: meta.name, kind: .tidy(.init(rules: [
            .init(application: findApplication("Xcode"), tiling: .left),
            .init(application: findApplication("GitHub"), tiling: .topRight),
            .init(application: findApplication("Ghostty"), tiling: .bottomRight),
          ]))),
          iconSize: iconSize,
        )
      }
    }

    try await commandAsset("KeyboardCommand") {
      generateCommandView(name: "Keyboard Command") { meta in
        enum Focus { @FocusState static var focus: AppFocus? }

        return KeyboardCommandView(
          Focus.$focus,
          metaData: meta,
          model: CommandViewModel.Kind.KeyboardModel(
            id: UUID().uuidString,
            command: .init(keyboardShortcuts: [
              .upArrow,
              .upArrow,
              .downArrow,
              .downArrow,
              .leftArrow,
              .rightArrow,
              .leftArrow,
              .rightArrow,
              .b,
              .a,
            ], iterations: 1),
          ),
          iconSize: iconSize,
        )
      }
    }

    try await commandAsset("InputSourceCommand") {
      generateCommandView(name: "Change Input Source") { meta in
        InputSourceCommandView(meta, model: CommandViewModel.Kind.InputSourceModel(id: UUID().uuidString, inputId: "", name: "English"), iconSize: iconSize)
          .environmentObject(InputSourceStore())
      }
    }

    try await commandAsset("MenuBarCommand") {
      generateCommandView(name: "Toggle Sidebar") { meta in
        MenuBarCommandView(meta, model: .init(id: UUID().uuidString, tokens: [
          MenuBarCommand.Token.menuItem(name: "View"),
          MenuBarCommand.Token.menuItems(name: "Show Sidebar", fallbackName: "Hide Sidebar"),
        ]), iconSize: iconSize)
      }
    }

    try await commandAsset("MouseCommand") {
      generateCommandView(name: "Click Focused Element", content: { meta in
        MouseCommandView(meta, model: .init(id: UUID().uuidString, kind: .click(.focused(.center))), iconSize: iconSize)
      })
    }

    try await commandAsset("OpenCommand") {
      generateCommandView(name: "Open Home Folder") { meta in
        meta.icon = Icon(findApplication("Finder"))
        return OpenCommandView(meta, model: .init(id: UUID().uuidString, path: "~/", applications: [
          findApplication("Finder"),
        ]), iconSize: iconSize)
      }
    }

    try await commandAsset("UrlCommand") {
      generateCommandView(name: "www.github.com") { meta in
        meta.icon = Icon(findApplication("Safari"))
        return OpenCommandView(meta, model: .init(id: UUID().uuidString, path: "https://www.github.com/", applications: [
          findApplication("Safari"),
        ]), iconSize: iconSize)
      }
    }

    try await commandAsset("DeeplinkCommand") {
      generateCommandView(name: "Raycast - My Schedule") { meta in
        meta.icon = Icon(findApplication("Raycast"))
        return OpenCommandView(meta, model: .init(id: UUID().uuidString, path: "raycast://extensions/raycast/calendar/my-schedule", applications: [
          findApplication("Raycast"),
        ]), iconSize: iconSize)
      }
    }

    try await commandAsset("ShortcutsCommand") {
      generateCommandView(name: "Toggle Low Power") { meta in
        ShortcutCommandView(meta, model: .init(id: UUID().uuidString, shortcutIdentifier: "Toggle Low Power"), iconSize: iconSize)
      }
    }

    try await commandAsset("ScriptCommand") {
      generateCommandView(name: "Run Python Script") { meta in
        ScriptCommandView(meta, model: .constant(.init(id: UUID().uuidString, source: .inline("""
        #!/usr/bin/env python3
        import webbrowser
        webbrowser.open("https://github.com/zenangst/KeyboardCowboy")
        """), scriptExtension: .shellScript, variableName: "", execution: .serial)), iconSize: iconSize, onSubmit: {})
      }
    }

    try await commandAsset("TypeCommand") {
      generateCommandView(name: "Think Different") { meta in
        TypeCommandView(meta, model: .init(id: UUID().uuidString, mode: .instant, input: """
        Here’s to the crazy ones. The misfits. The rebels. The troublemakers. The round pegs in the square holes. The ones who see things differently. They’re not fond of rules. And they have no respect for the status quo. You can quote them, disagree with them, glorify or vilify them.

        But the only thing you can’t do is ignore them. Because they change things. They invent. They imagine. They heal. They explore. They create. They inspire. They push the human race forward. Maybe they have to be crazy.

        How else can you stare at an empty canvas and see a work of art? Or sit in silence and hear a song that’s never been written? Or gaze at a red planet and see a laboratory on wheels? We make tools for these kinds of people.

        While some see them as the crazy ones, we see genius. Because the people who are crazy enough to think they can change the world, are the ones who do.
        """, actions: [.insertEnter]), iconSize: iconSize)
      }
    }
  }

  @MainActor private func commandAsset(_ filename: String, content: () -> some View) async throws {
    try await AssetGenerator.generate(filename: "Wiki/Commands/\(filename)", useIntrinsicContentSize: true, size: CGSize(width: 24, height: 24), content: content)
  }

  @MainActor private func generateCommandView(name: String, content: (inout CommandViewModel.MetaData) -> some View) -> some View {
    var meta = CommandViewModel.MetaData(name: name, namePlaceholder: "")
    let content = content(&meta)
      .frame(width: 500)
      .background {
        Color.black
          .padding(30)
          .shadow(color: .black.opacity(0.5), radius: 10, y: -45)
      }
      .padding(50)
      .designTime()
      .environmentObject(ViewModelPublisher(DetailViewModel.CommandsInfo(id: UUID().uuidString, commands: [], execution: .serial)))
    return content
  }

  @MainActor private func findApplication(_ name: String) -> Application {
    ApplicationStore.shared.applications.first(where: { $0.displayName == name })!
  }
}

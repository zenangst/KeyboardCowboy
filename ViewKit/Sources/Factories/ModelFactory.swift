import Foundation

class ModelFactory {

  // MARK: Public methods

  /// Used by `GroupList.swift`
  // swiftlint:disable function_body_length line_length
  func groupList() -> [GroupViewModel] {
    [
      GroupViewModel(
        id: UUID().uuidString,
        name: "Bundles", color: "#000", workflows: [
          WorkflowViewModel(
            id: UUID().uuidString, name: "Developer time",
            keyboardShortcuts: keyboardShortcuts(),
            commands: [
              CommandViewModel(
                name: "Open Calendar",
                kind: .application(ApplicationViewModel.calendar())),
              CommandViewModel(
                name: "Open Music",
                kind: .application(ApplicationViewModel.music())),
              CommandViewModel(
                name: "Open Xcode",
                kind: .application(ApplicationViewModel.xcode())),
              CommandViewModel(
                name: "Tile windows",
                kind: .appleScript(AppleScriptViewModel.empty())),
              CommandViewModel(
                name: "Generate GitHub issues overview",
                kind: .shellScript(ShellScriptViewModel.empty())),
              CommandViewModel(
                name: "Open client project",
                kind: .openFile(OpenFileViewModel(path: "/Users/christofferwinterkvist/Documents/Developer/KeyboardCowboy3/Keyboard-Cowboy.xcodeproj"))),
              CommandViewModel(
                name: "Open Github project",
                kind: .openUrl(OpenURLViewModel(url: URL(string: "https://www.github.com")!)))
            ]),

          WorkflowViewModel(
            name: "Design time", keyboardShortcuts: [], commands: [
              CommandViewModel(
                name: "Open Photoshop",

                kind: .application(ApplicationViewModel.photoshop())),
              CommandViewModel(
                name: "Open Sketch",

                kind: .application(ApplicationViewModel.sketch()))
            ]),
          WorkflowViewModel(
            name: "Filing hours", keyboardShortcuts: [], commands: [
              CommandViewModel(
                name: "Open Calendar",

                kind: .application(ApplicationViewModel.calendar()))
            ])
        ]),
      GroupViewModel(
        name: "Applications",
        color: "#EB5545",
        workflows: openWorkflows(
          ("Calendar", "/System/Applications/Calendar.app"),
          ("Contacts", "/System/Applications/Contacts.app"),
          ("Finder", "/System/Library/CoreServices/Finder.app"),
          ("Mail", "/System/Applications/Mail.app"),
          ("Safari", "/Applications/Safari.app"),
          ("Xcode", "/Applications/Xcode.app")
        )
      ),
      GroupViewModel(
        name: "Developer tools",
        color: "#F2A23C",
        workflows: openWorkflows(
          ("Xcode", "/Applications/Xcode.app"),
          ("Instruments", "/Applications/Xcode.app/Contents/Applications/Instruments.app"),
          ("Simulator", "/Applications/Xcode.app/Contents/Developer/Applications/Simulator.app"),
          ("Terminal", "/Applications/Utilities/Terminal.app")
        )
      ),
      GroupViewModel(
        name: "Folders",
        color: "#F9D64A",
        workflows: openWorkflows(("Home folder", "~"), ("Developer folder", "~/Developer"))
      ),
      GroupViewModel(
        name: "Files",
        color: "#6BD35F",
        workflows: openWorkflows(
          (".gitconfig", "~/.gitconfig"),
          ("Design project.sketch", "~/Applications"),
          ("Keyboard-Cowboy.xcodeproj", "~/Pictures"))
      ),
      GroupViewModel(
        name: "Keyboard shortcuts",
        color: "#3984F7",
        workflows: rebindWorkflows("⌥a to ←", "⌥w to ↑", "⌥d to →", "⌥s to ↓")
      ),
      GroupViewModel(
        name: "Safari",
        color: "#B263EA",
        workflows: runWorkflows("Share website", "Save as PDF")
      )
    ]
  }

  /// Used by `GroupListCell.swift`
  func groupListCell() -> GroupViewModel {
    GroupViewModel(
      name: "Developer tools",
      color: "#000",
      workflows: openWorkflows(
        ("Xcode", "/Applications/Xcode.app"),
        ("Instruments", "/Applications/Xcode.app/Contents/Applications/Instruments.app"),
        ("Simulator", "/Applications/Xcode.app/Contents/Developer/Applications/Simulator.app")
      )
    )
  }

  /// Used by `WorflowList.swift`
  func workflowList() -> [WorkflowViewModel] {
    openWorkflows(
      ("Calendar", "/System/Applications/Calendar.app"),
      ("Contacts", "/System/Applications/Contacts.app"),
      ("Finder", "/System/Library/CoreServices/Finder.app"),
      ("Mail", "/System/Applications/Mail.app"),
      ("Safari", "/Applications/Safari.app"),
      ("Xcode", "/Applications/Xcode.app")
    )
  }

  /// Used by `WorkflowListCell.swift`
  func workflowCell() -> WorkflowViewModel {
    workflow()
  }

  /// Used by `WorkflowView.swift`
  func workflowDetail() -> WorkflowViewModel {
    workflow()
  }

  func commands() -> [CommandViewModel] {
    [
      CommandViewModel(
        name: "Open Application",
        kind: .application(ApplicationViewModel.messages())),

      CommandViewModel(
        name: "Run AppleScript",
        kind: .appleScript(AppleScriptViewModel.empty())
      ),

      CommandViewModel(
        name: "Run Shellscript",
        kind: .shellScript(ShellScriptViewModel.empty())
      ),

      CommandViewModel(
        name: "Run a keyboard shortcut",
        kind: .keyboard(KeyboardShortcutViewModel.empty())
      ),

      CommandViewModel(
        name: "Open a file",
        kind: .openFile(OpenFileViewModel(
                          path: "~/Developer/Xcode.project",
                          application: ApplicationViewModel(
                            bundleIdentifier: "/Users/christofferwinterkvist/Documents/Developer/KeyboardCowboy3/Keyboard-Cowboy.xcodeproj",
                            name: "",
                            path: "/Users/christofferwinterkvist/Documents/Developer/KeyboardCowboy3/Keyboard-Cowboy.xcodeproj"))
        )),

      CommandViewModel(
        name: "Open a URL",
        kind: .openUrl(OpenURLViewModel(
                        url: URL(string: "https://github.com")!,
                        application: ApplicationViewModel(bundleIdentifier: "com.apple.Safari",
                                                          name: "Safari",
                                                          path: "/Applications/Safari.app"))
        ))
    ]
  }

  // MARK: Private methods

  private func openWorkflows(_ applicationNames: (String, String) ...) -> [WorkflowViewModel] {
    applicationNames.compactMap({
      WorkflowViewModel(
        name: "Open \($0)",
        keyboardShortcuts: [
          KeyboardShortcutViewModel(id: UUID().uuidString, key: "fn"),
          KeyboardShortcutViewModel(id: UUID().uuidString, key: "A")
        ],
        commands: [
          CommandViewModel(
            name: "Open \($0.0)",
            kind: .application(ApplicationViewModel(bundleIdentifier: $0.1, name: $0.1, path: $0.1)))]
      )
    })
  }

  private func runWorkflows(_ scriptNames: String ...) -> [WorkflowViewModel] {
    scriptNames.compactMap({
      WorkflowViewModel(
        name: "Run \($0) script",
        keyboardShortcuts: [],
        commands: [
          CommandViewModel(name: "Run \($0)", kind: .appleScript(AppleScriptViewModel.empty()))])

    })
  }

  private func rebindWorkflows(_ scriptNames: String ...) -> [WorkflowViewModel] {
    scriptNames.compactMap({
      WorkflowViewModel(
        name: "Rebind \($0)",
        keyboardShortcuts: [],
        commands: [
          CommandViewModel(name: "Rebind \($0)", kind: .keyboard(KeyboardShortcutViewModel.empty()))])
    })
  }

  private func openCommands(_ commands: (String, String) ...) -> [CommandViewModel] {
    commands.compactMap({
                          CommandViewModel(name: "Open \($0.0)",
                                           kind: .application(ApplicationViewModel(bundleIdentifier: $0.1, name: $0.1, path: $0.1))) })
  }

  func keyboardShortcuts() -> [KeyboardShortcutViewModel] {
    [.init(id: UUID().uuidString, key: "", modifiers: [.function]),
     .init(id: UUID().uuidString, key: "A", modifiers: [.option, .command])]
  }

  func installedApplications() -> [ApplicationViewModel] {
    [
      ApplicationViewModel.finder()
    ]
  }

  private func workflow() -> WorkflowViewModel {
    WorkflowViewModel(
      id: UUID().uuidString,
      name: "Developer workflow",
      keyboardShortcuts: keyboardShortcuts(),
      commands: commands())
  }
}

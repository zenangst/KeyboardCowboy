import Foundation

class ModelFactory {

  // MARK: Public methods

  /// Used by `GroupList.swift`
  // swiftlint:disable function_body_length
  func groupList() -> [GroupViewModel] {
    [
      GroupViewModel(
        id: UUID().uuidString,
        name: "Bundles", color: "#000", workflows: [
          WorkflowViewModel(id: UUID().uuidString, name: "Developer time",
                            keyboardShortcuts: keyboardShortcuts(),
                            commands: [
                              CommandViewModel(id: UUID().uuidString, name: "Open Calendar",
                                               kind: .application(path: "/System/Applications/Calendar.app",
                                                                  bundleIdentifier: "com.apple.calendar")),
                              CommandViewModel(id: UUID().uuidString, name: "Open Music",
                                               kind: .application(path: "/System/Applications/Music.app",
                                                                  bundleIdentifier: "com.apple.music")),
                              CommandViewModel(id: UUID().uuidString, name: "Open Xcode",
                                               kind: .application(path: "/Applications/Xcode.app",
                                                                  bundleIdentifier: "com.apple.dt.Xcode")),

                              CommandViewModel(id: UUID().uuidString, name: "Tile windows", kind: .appleScript),
                              CommandViewModel(id: UUID().uuidString, name: "Generate GitHub issues overview",
                                               kind: .shellScript),
                              CommandViewModel(
                                id: UUID().uuidString, name: "Open client project", kind: .openFile(
                                  path: "/Users/christofferwinterkvist/Documents/Developer/KeyboardCowboy3/Keyboard-Cowboy.xcodeproj",
                                  application: "/Users/christofferwinterkvist/Documents/Developer/KeyboardCowboy3/Keyboard-Cowboy.xcodeproj")),
                              CommandViewModel(id: UUID().uuidString, name: "Open Github project", kind: .openUrl(url: "https://www.github.com", application: "/Applications/Safari.app"))
                            ]),
          WorkflowViewModel(id: UUID().uuidString, name: "Design time", keyboardShortcuts: [], commands: [

            CommandViewModel(id: UUID().uuidString, name: "Open Photoshop",
                             kind: .application(path: "/Applications/Adobe Photoshop 2020/Adobe Photoshop 2020.app",
                                                bundleIdentifier: "com.adobe.Photoshop")),
            CommandViewModel(id: UUID().uuidString, name: "Open Sketch",
                             kind: .application(path: "/Applications/Sketch.app",
                                                bundleIdentifier: "com.bohemiancoding.sketch3"))
          ]),
          WorkflowViewModel(id: UUID().uuidString, name: "Filing hours", keyboardShortcuts: [], commands: [
            CommandViewModel(id: UUID().uuidString, name: "Open Calendar",
                             kind: .application(path: "/System/Applications/Calendar.app",
                                                bundleIdentifier: "com.apple.calendar"))
          ])
        ]),
      GroupViewModel(
        id: UUID().uuidString,
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
        id: UUID().uuidString,
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
        id: UUID().uuidString,
        name: "Folders",
        color: "#F9D64A",
        workflows: openWorkflows(("Home folder", "~"), ("Developer folder", "~/Developer"))
      ),
      GroupViewModel(
        id: UUID().uuidString,
        name: "Files",
        color: "#6BD35F",
        workflows: openWorkflows(
          (".gitconfig", "~/.gitconfig"),
          ("Design project.sketch", "~/Applications"),
          ("Keyboard-Cowboy.xcodeproj", "~/Pictures"))
      ),
      GroupViewModel(
        id: UUID().uuidString,
        name: "Keyboard shortcuts",
        color: "#3984F7",
        workflows: rebindWorkflows("⌥a to ←", "⌥w to ↑", "⌥d to →", "⌥s to ↓")
      ),
      GroupViewModel(
        id: UUID().uuidString,
        name: "Safari",
        color: "#B263EA",
        workflows: runWorkflows("Share website", "Save as PDF")
      )
    ]
  }

  /// Used by `GroupListCell.swift`
  func groupListCell() -> GroupViewModel {
    GroupViewModel(
      id: UUID().uuidString,
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

  // MARK: Private methods

  private func openWorkflows(_ applicationNames: (String, String) ...) -> [WorkflowViewModel] {
    applicationNames.compactMap({
      WorkflowViewModel(
        id: UUID().uuidString,
        name: "Open \($0)",
        keyboardShortcuts: [
          KeyboardShortcutViewModel(id: UUID().uuidString, name: "fn"),
          KeyboardShortcutViewModel(id: UUID().uuidString, name: "A")
        ],
        commands: [CommandViewModel(
                    name: "Open \($0.0)",
                    kind: .application(
                      path: "/Applications/\($0.1).app",
                      bundleIdentifier: $0.0))]
      )
    })
  }

  private func runWorkflows(_ scriptNames: String ...) -> [WorkflowViewModel] {
    scriptNames.compactMap({
      WorkflowViewModel(
        id: UUID().uuidString,
        name: "Run \($0) script",
        keyboardShortcuts: [],
        commands: [CommandViewModel(name: "Run \($0)", kind: .application(path: "/", bundleIdentifier: $0))])

    })
  }

  private func rebindWorkflows(_ scriptNames: String ...) -> [WorkflowViewModel] {
    scriptNames.compactMap({
      WorkflowViewModel(
        id: UUID().uuidString,
        name: "Rebind \($0)",
        keyboardShortcuts: [],
        commands: [CommandViewModel(name: "Rebind \($0)", kind: .application(path: "/", bundleIdentifier: $0))])

    })
  }

  private func openCommands(_ commands: (String, String) ...) -> [CommandViewModel] {
    commands.compactMap({ CommandViewModel(name: "Open \($0.0)",
                                           kind: .application(path: $0.1, bundleIdentifier: $0.0)) })
  }

  func keyboardShortcuts() -> [KeyboardShortcutViewModel] {
    [.init(id: UUID().uuidString, name: "fn"),
     .init(id: UUID().uuidString, name: "⌥⌘A")]
  }

  private func workflow() -> WorkflowViewModel {
    WorkflowViewModel(
      id: UUID().uuidString,
      name: "Developer workflow",
      keyboardShortcuts: keyboardShortcuts(),
      commands:
        [
          CommandViewModel(
            id: UUID().uuidString,
            name: "Open Xcode",
            kind: .application(path: "/Applications/Xcode.app", bundleIdentifier: "com.apple.dt.Xcode")),

          CommandViewModel(
            id: UUID().uuidString,
            name: "Run AppleScript",
            kind: .appleScript
          ),

          CommandViewModel(
            id: UUID().uuidString,
            name: "Run Shellscript",
            kind: .shellScript
          ),

          CommandViewModel(
            id: UUID().uuidString,
            name: "Go into fullscreen (⌘F)",
            kind: .keyboard
          ),

          CommandViewModel(
            id: UUID().uuidString,
            name: "Open recent project",
            kind: .openFile(
              path: "~/Developer/Xcode.project",
              application: "/Users/christofferwinterkvist/Documents/Developer/KeyboardCowboy3/Keyboard-Cowboy.xcodeproj")
          ),

          CommandViewModel(
            id: UUID().uuidString,
            name: "Open recent project",
            kind: .openUrl(url: "https://github.com", application: "/Applications/Safari.app")
          )
        ]
    )
  }
}

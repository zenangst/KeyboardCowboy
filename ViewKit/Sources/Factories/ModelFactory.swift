import Foundation
import ModelKit

class ModelFactory {

  // MARK: Public methods

  /// Used by `GroupList.swift`
  // swiftlint:disable function_body_length line_length
  func groupList() -> [ModelKit.Group] {
    [
      ModelKit.Group(
        id: UUID().uuidString,
        name: "Bundles", color: "#000", workflows: [
          Workflow(
            id: UUID().uuidString, name: "Developer time",
            keyboardShortcuts: keyboardShortcuts(),
            commands: [
              Command.application(.init(application: (Application.calendar()))),
              Command.application(.init(application: (Application.music()))),
              Command.application(.init(application: (Application.xcode()))),
              Command.script(.appleScript(.path("foo"), UUID().uuidString)),
              Command.script(.shell(.path("foo"), UUID().uuidString)),
              Command.open(.init(path: "/Users/christofferwinterkvist/Documents/Developer/KeyboardCowboy3/Keyboard-Cowboy.xcodeproj")),
              Command.open(.init(path: "https://www.github.com"))
            ]),

          Workflow(
            name: "Design time", keyboardShortcuts: [], commands: [
              Command.application(.init(application: Application.photoshop())),
              Command.application(.init(application: Application.sketch()))
            ]),
          Workflow(
            name: "Filing hours", keyboardShortcuts: [], commands: [
              Command.application(.init(application: Application.calendar()))
            ])
        ]),
      ModelKit.Group(
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
      ModelKit.Group(
        name: "Developer tools",
        color: "#F2A23C",
        workflows: openWorkflows(
          ("Xcode", "/Applications/Xcode.app"),
          ("Instruments", "/Applications/Xcode.app/Contents/Applications/Instruments.app"),
          ("Simulator", "/Applications/Xcode.app/Contents/Developer/Applications/Simulator.app"),
          ("Terminal", "/Applications/Utilities/Terminal.app")
        )
      ),
      ModelKit.Group(
        name: "Folders",
        color: "#F9D64A",
        workflows: openWorkflows(("Home folder", "~"), ("Developer folder", "~/Developer"))
      ),
      ModelKit.Group(
        name: "Files",
        color: "#6BD35F",
        workflows: openWorkflows(
          (".gitconfig", "~/.gitconfig"),
          ("Design project.sketch", "~/Applications"),
          ("Keyboard-Cowboy.xcodeproj", "~/Pictures"))
      ),
      ModelKit.Group(
        name: "Keyboard shortcuts",
        color: "#3984F7",
        workflows: rebindWorkflows("⌥a to ←", "⌥w to ↑", "⌥d to →", "⌥s to ↓")
      ),
      ModelKit.Group(
        name: "Safari",
        color: "#B263EA",
        workflows: runWorkflows("Share website", "Save as PDF")
      )
    ]
  }

  /// Used by `GroupListCell.swift`
  func groupListCell() -> ModelKit.Group {
    ModelKit.Group(
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
  func workflowList() -> [Workflow] {
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
  func workflowCell() -> Workflow {
    workflow()
  }

  /// Used by `WorkflowView.swift`
  func workflowDetail() -> Workflow {
    workflow()
  }

  func commands() -> [Command] {
    let result = [
      Command.application(.init(application: Application.messages())),
      Command.script(ScriptCommand.empty(.appleScript)),
      Command.script(ScriptCommand.empty(.shell)),
      Command.keyboard(.init(keyboardShortcut: KeyboardShortcut.empty())),
      Command.open(.init(application: Application(
                          bundleIdentifier: "/Users/christofferwinterkvist/Documents/Developer/KeyboardCowboy3/Keyboard-Cowboy.xcodeproj",
                          bundleName: "",
                          path: "/Users/christofferwinterkvist/Documents/Developer/KeyboardCowboy3/Keyboard-Cowboy.xcodeproj"),
                         path: "~/Developer/Xcode.project")),

      Command.open(.init(application: Application.safari(),
                         path: "https://github.com"))
    ]

    return result
  }

  // MARK: Private methods

  private func openWorkflows(_ applicationNames: (String, String) ...) -> [Workflow] {
    applicationNames.compactMap({
      Workflow(
        name: "Open \($0)",
        keyboardShortcuts: [
          KeyboardShortcut(id: UUID().uuidString, key: "fn"),
          KeyboardShortcut(id: UUID().uuidString, key: "A")
        ],
        commands: [
          Command.application(.init(application: Application(bundleIdentifier: $0.1, bundleName: $0.1, path: $0.1)))
        ]
      )
    })
  }

  private func runWorkflows(_ scriptNames: String ...) -> [Workflow] {
    scriptNames.compactMap({
      Workflow(
        name: "Run \($0) script",
        keyboardShortcuts: [],
        commands: [
          Command.script(.appleScript(.path(""), "Run \($0)"))
        ])
    })
  }

  private func rebindWorkflows(_ scriptNames: String ...) -> [Workflow] {
    scriptNames.compactMap({
      Workflow(
        name: "Rebind \($0)",
        keyboardShortcuts: [],
        commands: [
          Command.keyboard(.init(keyboardShortcut: KeyboardShortcut.empty()))
        ])
    })
  }

  private func openCommands(_ commands: (String, String) ...) -> [Command] {
    commands.compactMap({
      Command.application(.init(application: Application(bundleIdentifier: $0.1, bundleName: $0.1, path: $0.1)))
    })
  }

    func keyboardShortcuts() -> [ModelKit.KeyboardShortcut] {
    [.init(id: UUID().uuidString, key: "", modifiers: [.function]),
     .init(id: UUID().uuidString, key: "A", modifiers: [.option, .command])]
  }

  func installedApplications() -> [Application] {
    [
      Application.finder()
    ]
  }

  private func workflow() -> Workflow {
    Workflow(
      id: UUID().uuidString,
      name: "Developer workflow",
      keyboardShortcuts: keyboardShortcuts(),
      commands: commands())
  }
}

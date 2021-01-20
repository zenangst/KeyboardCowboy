import Foundation
import ModelKit

class ModelFactory {

  // MARK: Public methods

  /// Used by `GroupList.swift`
  // swiftlint:disable function_body_length line_length
  func groupList() -> [ModelKit.Group] {
    [
      ModelKit.Group(
        id: "Group 1",
        name: "Bundles", color: "#000", workflows: [
          Workflow(
            id: "Workflow 1",
            name: "Developer time",
            keyboardShortcuts: keyboardShortcuts(id: "Keyboard Shortcut"),
            commands: [
              Command.application(.init(id: "Calendar 1", application: (Application.calendar(id: "Calendar")))),
              Command.application(.init(id: "Music 1", application: (Application.music(id: "Music")))),
              Command.application(.init(id: "Xcode 1", application: (Application.xcode(id: "Xcode")))),
              Command.script(.appleScript(id: "AppleScript 1", name: nil, source: .path("foo"))),
              Command.script(.shell(id: "ShellScript 1", name: nil, source: .path("foo"))),
              Command.open(.init(id: "Open 1", path: "/Users/christofferwinterkvist/Documents/Developer/KeyboardCowboy3/Keyboard-Cowboy.xcodeproj")),
              Command.open(.init(id: "Open 2", path: "https://www.github.com"))
            ]),

          Workflow(
            id: "Design time 1",
            name: "Design time", keyboardShortcuts: [], commands: [
              Command.application(.init(id: "Application 1", application: Application.photoshop(id: "Photoshop"))),
              Command.application(.init(id: "Application 2", application: Application.sketch(id: "Sketch")))
            ]),
          Workflow(
            id: "Filing hours 1",
            name: "Filing hours", keyboardShortcuts: [], commands: [
              Command.application(.init(id: "Application 1", application: Application.calendar(id: "Calendar")))
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
  func workflowDetail(_ commands: [Command]? = nil, name: String? = nil) -> Workflow {
    workflow(commands, name: name)
  }

  func commands(id: String = UUID().uuidString) -> [Command] {
    let result = [
      applicationCommand(id: id),
      appleScriptCommand(id: id),
      shellScriptCommand(id: id),
      keyboardCommand(id: id),
      openCommand(id: id),
      urlCommand(id: id, application: nil),
      typeCommand(id: id),
      Command.builtIn(.init(kind: .quickRun))
    ]

    return result
  }

  func applicationCommand(id: String) -> Command {
    Command.application(.init(id: id, application: Application.messages(name: "Application")))
  }

  func appleScriptCommand(id: String) -> Command {
    Command.script(ScriptCommand.empty(.appleScript, id: id))
  }

  func shellScriptCommand(id: String) -> Command {
    Command.script(ScriptCommand.empty(.shell, id: id))
  }

  func keyboardCommand(id: String) -> Command {
    Command.keyboard(.init(id: id, keyboardShortcut: KeyboardShortcut.empty()))
  }

  func openCommand(id: String) -> Command {
    Command.open(.init(id: id,
                       application: Application(
                        bundleIdentifier: "/Users/christofferwinterkvist/Documents/Developer/KeyboardCowboy3/Keyboard-Cowboy.xcodeproj",
                        bundleName: "",
                        path: "/Users/christofferwinterkvist/Documents/Developer/KeyboardCowboy3/Keyboard-Cowboy.xcodeproj"),
                       path: "~/Developer/Xcode.project"))
  }

  func urlCommand(id: String, application: Application?) -> Command {
    Command.open(.init(id: id,
                       application: application,
                       path: "https://github.com"))
  }

  func typeCommand(id: String) -> Command {
    Command.type(.init(id: id, name: "Type input", input: ""))
  }

  // MARK: Private methods

  private func openWorkflows(_ applicationNames: (String, String) ...) -> [Workflow] {
    applicationNames.enumerated().compactMap({ offset, element in
      Workflow(
        id: "Workflow: \(offset)",
        name: "Open \(element.0)",
        keyboardShortcuts: [
          KeyboardShortcut(id: "KeyboardShortcut\(offset)-1", key: "fn"),
          KeyboardShortcut(id: "KeyboardShortcut\(offset)-2", key: "A")
        ],
        commands: [
          Command.application(.init(application: Application(
                                      id: "Application ID \(offset)",
                                      bundleIdentifier: element.1,
                                      bundleName: element.1,
                                      path: element.1)))
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
          Command.script(.appleScript(id: "Run \($0)", name: nil, source: .path("")))
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

  func keyboardShortcuts(id: String = UUID().uuidString) -> [ModelKit.KeyboardShortcut] {
    [
      .init(id: "\(id)-1", key: "A", modifiers: [.function]),
      .init(id: "\(id)-2", key: "A", modifiers: [.option, .command]),
      .init(id: "\(id)-3", key: "X", modifiers: [.option]),
    ]
  }

  func installedApplications() -> [Application] {
    [
      Application.finder()
    ]
  }

  private func workflow(_ commands: [Command]? = nil, name: String? = nil) -> Workflow {
    Workflow(
      id: UUID().uuidString,
      name: name ?? "Developer Workflow",
      keyboardShortcuts: keyboardShortcuts(),
      commands: commands ?? self.commands(id: UUID().uuidString))
  }
}

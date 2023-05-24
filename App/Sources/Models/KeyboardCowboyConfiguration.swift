import Cocoa
import Foundation

struct KeyboardCowboyConfiguration: Identifiable, Codable, Hashable, Sendable {
  let id: String
  var name: String
  var groups: [WorkflowGroup]

  init(id: String = UUID().uuidString, name: String, groups: [WorkflowGroup]) {
    self.id = id
    self.name = name
    self.groups = groups
  }

  static func empty() -> KeyboardCowboyConfiguration {
    KeyboardCowboyConfiguration(id: UUID().uuidString, name: "Untitled Configuration", groups: [])
  }

  static func `default`() -> KeyboardCowboyConfiguration {
    let editorWorkflow: Workflow

    if !NSWorkspace.shared.urlsForApplications(withBundleIdentifier: "com.apple.dt.Xcode").isEmpty {
      editorWorkflow = Workflow(
        name: "Switch to Xcode",
        trigger: .keyboardShortcuts([.init(key: "E", modifiers: [.function])]),
        commands: [
          .application(
            .init(application: .xcode())
          )
        ]
      )
    } else {
      editorWorkflow = Workflow(
        name: "Switch to TextEdit",
        trigger: .keyboardShortcuts([.init(key: "E", modifiers: [.function])]),
        commands: [
          .application(
            .init(application: .init(bundleIdentifier: "com.apple.TextEdit",
                                     bundleName: "TextEdit",
                                     path: "/System/Applications/TextEdit.app"))
          )
        ]
      )
    }

    return KeyboardCowboyConfiguration(
      name: "Default Configuration",
      groups: [
        WorkflowGroup(symbol: "autostartstop", name: "Automation", color: "#EB5545"),
        WorkflowGroup(symbol: "app.dashed", name: "Applications", color: "#F2A23C", workflows: [
          Workflow(
            name: "Switch to Finder",
            trigger: .keyboardShortcuts([.init(key: "F", modifiers: [.function])]),
            commands: [
              .application(
                .init(application: .finder())
              )
            ]
          ),
          editorWorkflow,
          Workflow(
            name: "Switch to Terminal",
            trigger: .keyboardShortcuts([.init(key: "T", modifiers: [.function])]),
            commands: [
              .application(
                .init(application: .init(
                  bundleIdentifier: "com.apple.Terminal",
                  bundleName: "Terminal",
                  path: "/System/Applications/Utilities/Terminal.app"))
              )
            ]
          ),

          Workflow(
            name: "Switch to Safari",
            trigger: .keyboardShortcuts([.init(key: "S", modifiers: [.function])]),
            commands: [
              .application(
                .init(application: .safari())
              )
            ]
          ),
          Workflow(
            name: "Open System Settings",
            trigger: .keyboardShortcuts([.init(key: ",", modifiers: [.function])]),
            commands: [
              .application(
                .init(application: .systemSettings())
              )
            ]
          ),
        ]),
        WorkflowGroup(symbol: "applescript", name: "AppleScripts", color: "#F9D64A",
                     workflows: [
                      Workflow(name: "Open a specific note",
                               commands: [
                                .script(.appleScript(name: "Show note", source: .inline("""
                                  tell application "Notes"
                                      show note "awesome note"
                                  end tell
                                  """)))
                               ])
                     ]),
        WorkflowGroup(symbol: "folder", name: "Files & Folders", color: "#6BD35F",
                      workflows: [
                        Workflow(name: "Open Home folder",
                                 trigger: .keyboardShortcuts([.init(key: "H", modifiers: [.function])]),
                                 commands: [
                                  .open(.init(path: ("~/" as NSString).expandingTildeInPath))
                                 ]),
                        Workflow(name: "Open Documents folder",
                                 trigger: .keyboardShortcuts([]),
                                 commands: [
                                  .open(.init(path: ("~/Documents" as NSString).expandingTildeInPath))
                                 ]),
                        Workflow(name: "Open Downloads folder",
                                 trigger: .keyboardShortcuts([]),
                                 commands: [
                                  .open(.init(path: ("~/Downloads" as NSString).expandingTildeInPath))
                                 ]),
                      ]),
        WorkflowGroup(symbol: "app.connected.to.app.below.fill",
                      name: "Rebinding",
                      color: "#3984F7",
                      workflows: [
                        Workflow(name: "Vim bindings H to ←",
                                 trigger: .keyboardShortcuts([.init(key: "H", modifiers: [.option])]),
                                 commands: [
                                  .keyboard(.init(keyboardShortcut: .init(key: "←")))
                                 ], isEnabled: false),
                        Workflow(name: "Vim bindings J to ↓",
                                 trigger: .keyboardShortcuts([.init(key: "J", modifiers: [.option])]),
                                 commands: [
                                  .keyboard(.init(keyboardShortcut: .init(key: "↓")))
                                 ], isEnabled: false),
                        Workflow(name: "Vim bindings K to ↑",
                                 trigger: .keyboardShortcuts([.init(key: "K", modifiers: [.option])]),
                                 commands: [
                                  .keyboard(.init(keyboardShortcut: .init(key: "↑")))
                                 ], isEnabled: false),
                        Workflow(name: "Vim bindings L to →",
                                 trigger: .keyboardShortcuts([.init(key: "L", modifiers: [.option])]),
                                 commands: [
                                  .keyboard(.init(keyboardShortcut: .init(key: "→")))
                                 ], isEnabled: false)
                      ]),
        WorkflowGroup(symbol: "flowchart", name: "Shortcuts", color: "#B263EA"),
        WorkflowGroup(symbol: "terminal", name: "ShellScripts", color: "#5D5FDE"),
        WorkflowGroup(symbol: "laptopcomputer", name: "System", color: "#A78F6D"),
        WorkflowGroup(symbol: "safari", name: "Websites", color: "#98989D",
                      workflows: [
                        Workflow(name: "Open apple.com",
                                 trigger: .keyboardShortcuts([
                                  .init(key: "⇥", modifiers: [.function]),
                                  .init(key: "A"),
                                 ]),
                                 commands: [.open(.init(path: "https://www.apple.com"))]),
                        Workflow(name: "Open github.com",
                                 trigger: .keyboardShortcuts([
                                  .init(key: "⇥", modifiers: [.function]),
                                  .init(key: "G"),
                                 ]),
                                 commands: [.open(.init(path: "https://www.github.com"))]),
                        Workflow(name: "Open imdb.com",
                                 trigger: .keyboardShortcuts([
                                  .init(key: "⇥", modifiers: [.function]),
                                  .init(key: "I"),
                                 ]),
                                 commands: [.open(.init(path: "https://www.imdb.com"))]),
                      ]),
        WorkflowGroup(name: "Mail", color:"#3984F7",
                      rule: Rule.init(bundleIdentifiers: ["com.apple.mail"]),
                      workflows: [
                        Workflow(name: "Type mail signature",
                                 trigger: .keyboardShortcuts([.init(key: "S", modifiers: [.function, .command])]),
                                 commands: [
                                  .type(.init(name: "Signature", input: """
Stay hungry, stay awesome!
--------------------------
xoxo
\(NSFullUserName())
"""
                                             ))
                                 ])
                      ])
      ])
  }
}

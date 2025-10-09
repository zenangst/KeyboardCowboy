import Cocoa
import Foundation

struct KeyboardCowboyConfiguration: Identifiable, Codable, Hashable, Sendable {
  let id: String
  var name: String
  var userModes: [UserMode]
  var groups: [WorkflowGroup]

  init(id: String = UUID().uuidString, name: String,
       userModes: [UserMode], groups: [WorkflowGroup])
  {
    self.id = id
    self.name = name
    self.userModes = userModes
    self.groups = groups
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(name, forKey: .name)
    try container.encode(userModes, forKey: .userModes)
    try container.encode(groups, forKey: .groups)
  }

  enum CodingKeys: CodingKey {
    case id
    case name
    case userModes
    case groups
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    name = try container.decode(String.self, forKey: .name)
    userModes = try container.decodeIfPresent([UserMode].self, forKey: .userModes) ?? []
    groups = try container.decode([WorkflowGroup].self, forKey: .groups)
  }

  static func empty() -> KeyboardCowboyConfiguration {
    KeyboardCowboyConfiguration(
      id: UUID().uuidString,
      name: "Untitled Configuration",
      userModes: [],
      groups: [],
    )
  }

  static func `default`() -> KeyboardCowboyConfiguration {
    let editorWorkflow = if !NSWorkspace.shared.urlsForApplications(withBundleIdentifier: "com.apple.dt.Xcode").isEmpty {
      Workflow(
        name: "Switch to Xcode",
        trigger: .keyboardShortcuts(.init(shortcuts: [.init(key: "E", modifiers: [.function])])),
        commands: [
          .application(
            .init(application: .xcode()),
          ),
        ],
      )
    } else {
      Workflow(
        name: "Switch to TextEdit",
        trigger: .keyboardShortcuts(.init(shortcuts: [.init(key: "E", modifiers: [.function])])),
        commands: [
          .application(
            .init(application: .init(bundleIdentifier: "com.apple.TextEdit",
                                     bundleName: "TextEdit",
                                     displayName: "TextEdit",
                                     path: "/System/Applications/TextEdit.app")),
          ),
        ],
      )
    }

    return KeyboardCowboyConfiguration(
      name: "Default Configuration",
      userModes: [],
      groups: [
        WorkflowGroup(symbol: "autostartstop", name: "Automation", color: "#EB5545"),
        WorkflowGroup(symbol: "app.dashed", name: "Applications", color: "#F2A23C", workflows: [
          Workflow(
            name: "Switch to Finder",
            trigger: .keyboardShortcuts(.init(shortcuts: [.init(key: "F", modifiers: [.function])])),
            commands: [
              .application(
                .init(application: .finder()),
              ),
            ],
          ),
          editorWorkflow,
          Workflow(
            name: "Switch to Terminal",
            trigger: .keyboardShortcuts(.init(shortcuts: [.init(key: "T", modifiers: [.function])])),
            commands: [
              .application(
                .init(application: .init(
                  bundleIdentifier: "com.apple.Terminal",
                  bundleName: "Terminal",
                  displayName: "Terminal",
                  path: "/System/Applications/Utilities/Terminal.app",
                )),
              ),
            ],
          ),

          Workflow(
            name: "Switch to Safari",
            trigger: .keyboardShortcuts(.init(shortcuts: [.init(key: "S", modifiers: [.function])])),
            commands: [
              .application(
                .init(application: .safari()),
              ),
            ],
          ),
          Workflow(
            name: "Open System Settings",
            trigger: .keyboardShortcuts(.init(shortcuts: [.init(key: ",", modifiers: [.function])])),
            commands: [
              .application(
                .init(application: .systemSettings()),
              ),
            ],
          ),
        ]),
        WorkflowGroup(symbol: "applescript", name: "AppleScripts", color: "#F9D64A",
                      workflows: [
                        Workflow(name: "Open a specific note",
                                 commands: [
                                   .script(.init(name: "Show note", kind: .appleScript(variant: .regular), source: .inline("""
                                   tell application "Notes"
                                       show note "awesome note"
                                   end tell
                                   """), notification: nil)),
                                 ]),
                      ]),
        WorkflowGroup(symbol: "folder", name: "Files & Folders", color: "#6BD35F",
                      workflows: [
                        Workflow(name: "Open Home folder",
                                 trigger: .keyboardShortcuts(.init(shortcuts: [.init(key: "H", modifiers: [.function])])),
                                 commands: [
                                   .open(.init(path: ("~/" as NSString).expandingTildeInPath)),
                                 ]),
                        Workflow(name: "Open Documents folder",
                                 trigger: .keyboardShortcuts(.init(shortcuts: [])),
                                 commands: [
                                   .open(.init(path: ("~/Documents" as NSString).expandingTildeInPath)),
                                 ]),
                        Workflow(name: "Open Downloads folder",
                                 trigger: .keyboardShortcuts(.init(shortcuts: [])),
                                 commands: [
                                   .open(.init(path: ("~/Downloads" as NSString).expandingTildeInPath)),
                                 ]),
                      ]),
        WorkflowGroup(symbol: "app.connected.to.app.below.fill",
                      name: "Rebinding",
                      color: "#3984F7",
                      workflows: [
                        Workflow(name: "Vim bindings H to ←",
                                 trigger: .keyboardShortcuts(.init(shortcuts: [.init(key: "H", modifiers: [.leftOption])])),
                                 isEnabled: false, commands: [
                                   .keyboard(.init(name: "", kind: .key(command: .init(keyboardShortcuts: [.init(key: "←")], iterations: 1)))),
                                 ]),
                        Workflow(name: "Vim bindings J to ↓",
                                 trigger: .keyboardShortcuts(.init(shortcuts: [.init(key: "J", modifiers: [.leftOption])])),
                                 isEnabled: false, commands: [
                                   .keyboard(.init(name: "", kind: .key(command: .init(keyboardShortcuts: [.init(key: "↓")], iterations: 1)))),
                                 ]),
                        Workflow(name: "Vim bindings K to ↑",
                                 trigger: .keyboardShortcuts(.init(shortcuts: [.init(key: "K", modifiers: [.leftOption])])),
                                 isEnabled: false, commands: [
                                   .keyboard(.init(name: "", kind: .key(command: .init(keyboardShortcuts: [.init(key: "↑")], iterations: 1)))),
                                 ]),
                        Workflow(name: "Vim bindings L to →",
                                 trigger: .keyboardShortcuts(.init(shortcuts: [.init(key: "L", modifiers: [.leftOption])])),
                                 isEnabled: false, commands: [
                                   .keyboard(.init(name: "", kind: .key(command: .init(keyboardShortcuts: [.init(key: "→")], iterations: 1)))),
                                 ]),
                      ]),
        WorkflowGroup(symbol: "flowchart", name: "Shortcuts", color: "#B263EA"),
        WorkflowGroup(symbol: "terminal", name: "ShellScripts", color: "#5D5FDE"),
        WorkflowGroup(symbol: "laptopcomputer", name: "System", color: "#A78F6D"),
        WorkflowGroup(symbol: "safari", name: "Websites", color: "#98989D",
                      workflows: [
                        Workflow(name: "Open apple.com",
                                 trigger: .keyboardShortcuts(.init(shortcuts: [
                                   .init(key: "⇥", modifiers: [.function]),
                                   .init(key: "A"),
                                 ])),
                                 commands: [.open(.init(path: "https://www.apple.com"))]),
                        Workflow(name: "Open github.com",
                                 trigger: .keyboardShortcuts(.init(shortcuts: [
                                   .init(key: "⇥", modifiers: [.function]),
                                   .init(key: "G"),
                                 ])),
                                 commands: [.open(.init(path: "https://www.github.com"))]),
                        Workflow(name: "Open imdb.com",
                                 trigger: .keyboardShortcuts(.init(shortcuts: [
                                   .init(key: "⇥", modifiers: [.function]),
                                   .init(key: "I"),
                                 ])),
                                 commands: [.open(.init(path: "https://www.imdb.com"))]),
                      ]),
        WorkflowGroup(name: "Mail", color: "#3984F7",
                      rule: Rule(allowedBundleIdentifiers: ["com.apple.mail"]),
                      workflows: [
                        Workflow(name: "Type mail signature",
                                 trigger: .keyboardShortcuts(.init(shortcuts: [.init(key: "S", modifiers: [.function, .leftCommand])])),
                                 commands: [
                                   .text(.init(.insertText(.init("""
                                   Stay hungry, stay awesome!
                                   --------------------------
                                   xoxo
                                   \(NSFullUserName())
                                   """, mode: .instant, meta: .init(id: UUID().uuidString, name: "Signature", isEnabled: true, notification: nil), actions: [.insertEnter])))),
                                 ]),
                      ]),
      ],
    )
  }
}

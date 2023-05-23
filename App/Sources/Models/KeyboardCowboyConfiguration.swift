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
    KeyboardCowboyConfiguration(
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
        WorkflowGroup(symbol: "applescript", name: "AppleScripts", color: "#F9D64A"),
        WorkflowGroup(symbol: "folder", name: "Files & Folders", color: "#6BD35F",
                      workflows: [
                        Workflow(name: "Open Home folder",
                                 trigger: .keyboardShortcuts([.init(key: "H", modifiers: [.function])]),
                                 commands: [
                                  .open(.init(path: "~/"))
                                 ])
                      ]),
        WorkflowGroup(symbol: "app.connected.to.app.below.fill", name: "Rebinding", color: "#3984F7"),
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

                      ]),
      ])
  }
}

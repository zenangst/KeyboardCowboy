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

  static func initial() -> KeyboardCowboyConfiguration {
    KeyboardCowboyConfiguration(
      name: "Default Configuration",
      groups: [
        .init(symbol: "autostartstop", name: "Automation", color: "#EB5545"),
        .init(symbol: "app.dashed", name: "Applications", color: "#F2A23C"),
        .init(symbol: "applescript", name: "AppleScripts", color: "#F9D64A"),
        .init(symbol: "folder", name: "Files & Folders", color: "#6BD35F"),
        .init(symbol: "app.connected.to.app.below.fill", name: "Rebinding", color: "#3984F7"),
        .init(symbol: "flowchart", name: "Shortcuts", color: "#B263EA"),
        .init(symbol: "terminal", name: "ShellScripts", color: "#5D5FDE"),
        .init(symbol: "laptopcomputer", name: "System", color: "#A78F6D"),
        .init(symbol: "safari", name: "Websites", color: "#98989D"),
      ])
  }
}

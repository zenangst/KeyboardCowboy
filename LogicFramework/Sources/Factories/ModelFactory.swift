import Foundation

class ModelFactory {
  static func application() -> Application {
    Application(bundleIdentifier: "com.apple.Finder",
                bundleName: "Finder",
                path: "/System/Library/CoreServices/Finder.app")
  }

  func applicationCommand() -> ApplicationCommand {
    .init(application: Self.application())
  }

  func days() -> [Rule.Day] {
    [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
  }

  func group(name: String = "Global shortcuts",
             rule: Rule? = nil,
             workflows: ((ModelFactory) -> [Workflow])? = nil) -> Group {
    Group(name: name,
          rule: rule ?? self.rule(),
          workflows: workflows?(self) ?? [workflow()])
  }

  func keyboardCommand() -> KeyboardCommand {
    .init(keyboardShortcut: keyboardShortcut())
  }

  func keyboardShortcut(key: String = "A", modifiers: [ModifierKey]? = nil) -> KeyboardShortcut {
    .init(key: key, modifiers: modifiers)
  }

  func openCommand(application: Application? = ModelFactory.application()) -> OpenCommand {
    .init(application: application, path: "~/Desktop/new_real_final_draft_Copy_42.psd")
  }

  func rule() -> Rule {
    Rule(applications: [Self.application()], days: days())
  }

  func scriptCommands() -> [ScriptCommand] {
    let path = "/tmp/file"
    let script = "#!/usr/bin/env fish"
    return [
      .appleScript(.inline(script)),
      .appleScript(.path(path)),
      .shell(.inline(script)),
      .shell(.path(path))
    ]
  }

  func keyboardShortcut(_ modifiers: [ModifierKey]) -> KeyboardShortcut {
    .init(key: "A", modifiers: modifiers)
  }

  func workflow(keyboardShortcuts: ((ModelFactory) -> [KeyboardShortcut])? = nil,
                commands: ((ModelFactory) -> [Command])? = nil,
                name: String = "Open/active Finder") -> Workflow {
    Workflow(
      commands: commands?(self) ?? [.application(applicationCommand())],
      keyboardShortcuts: keyboardShortcuts?(self) ?? [keyboardShortcut(modifiers: [.control, .option])],
      name: name)
  }
}

import Foundation

public class ModelFactory {
  static func application(id: String = UUID().uuidString) -> Application {
    Application(id: id,
                bundleIdentifier: "com.apple.Finder",
                bundleName: "Finder",
                path: "/System/Library/CoreServices/Finder.app")
  }

  func applicationCommand(id: String = UUID().uuidString) -> ApplicationCommand {
    .init(id: id, application: Self.application(id: id))
  }

  func days() -> [Rule.Day] {
    [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
  }

  func group(id: String = UUID().uuidString,
             name: String = "Global shortcuts",
             rule: Rule? = nil,
             workflows: ((ModelFactory) -> [Workflow])? = nil) -> Group {
    Group(id: id,
          name: name,
          color: "#fff",
          rule: rule ?? self.rule(id: id),
          workflows: workflows?(self) ?? [workflow(id: id)])
  }

  func keyboardCommand(id: String = UUID().uuidString) -> KeyboardCommand {
    .init(id: id, keyboardShortcut: keyboardShortcut(id: id))
  }

  func keyboardShortcut(id: String = UUID().uuidString, key: String = "A",
                        modifiers: [ModifierKey]? = nil) -> KeyboardShortcut {
    .init(id: id, key: key, modifiers: modifiers)
  }

  func openCommand(id: String = UUID().uuidString,
                   application: Application? = ModelFactory.application()) -> OpenCommand {
    .init(id: id, application: application, path: "~/Desktop/new_real_final_draft_Copy_42.psd")
  }

  func rule(id: String = UUID().uuidString) -> Rule {
    Rule(id: id, bundleIdentifiers: [Self.application(id: id).bundleIdentifier], days: days())
  }

  func scriptCommands(id: String = UUID().uuidString) -> [ScriptCommand] {
    let path = "/tmp/file"
    let script = "#!/usr/bin/env fish"
    return [
      .appleScript(id: id, name: nil, source: .inline(script)),
      .appleScript(id: id, name: nil, source: .path(path)),
      .shell(id: id, name: nil, source: .inline(script)),
      .shell(id: id, name: nil, source: .path(path))
    ]
  }

  func keyboardShortcut(_ modifiers: [ModifierKey]) -> KeyboardShortcut {
    .init(key: "A", modifiers: modifiers)
  }

  func workflow(id: String = UUID().uuidString,
                keyboardShortcuts: ((ModelFactory) -> [KeyboardShortcut])? = nil,
                commands: ((ModelFactory) -> [Command])? = nil,
                name: String = "Open/active Finder") -> Workflow {
    Workflow(
      id: id,
      name: name,
      trigger: .keyboardShortcuts(keyboardShortcuts?(self) ?? [keyboardShortcut(id: id, modifiers: [.control, .option])]),
      commands: commands?(self) ?? [.application(applicationCommand(id: id))])
  }
}

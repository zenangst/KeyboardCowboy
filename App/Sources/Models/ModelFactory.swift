import Apps
import Foundation

public class ModelFactory {
  static func application(id: String = UUID().uuidString) -> Application {
    Application(bundleIdentifier: "com.apple.Finder",
                bundleName: "Finder",
                path: "/System/Library/CoreServices/Finder.app")
  }

  func commands(id: String = UUID().uuidString) -> [Command] {
    let result: [Command] = [
      Command.application(applicationCommand(id: id)),
      Command.appleScriptCommand(id: id),
      Command.shellScriptCommand(id: id),
      Command.shortcutCommand(id: id),
      Command.keyboardCommand(id: id),
      Command.openCommand(id: id),
      Command.urlCommand(id: id, application: nil),
      Command.typeCommand(id: id),
      Command.builtIn(.init(kind: .quickRun))
    ]

    return result
  }

  func applicationCommand(id: String = UUID().uuidString) -> ApplicationCommand {
    .init(id: id, action: .open, application: Self.application(id: id))
  }

  func appleScriptCommand(id: String) -> Command {
    Command.script(ScriptCommand.empty(.appleScript, id: id))
  }

  func shellScriptCommand(id: String) -> Command {
    Command.script(ScriptCommand.empty(.shell, id: id))
  }

  func urlCommand(id: String, application: Application?) -> Command {
    Command.open(.init(id: id,
                       application: application,
                       path: "https://github.com"))
  }

  func typeCommand(id: String) -> Command {
    Command.type(.init(id: id, name: "Type input", input: ""))
  }

  func days() -> [Rule.Day] {
    [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
  }

  func group(id: String = UUID().uuidString,
             name: String = "Global shortcuts",
             rule: Rule? = nil,
             workflows: ((ModelFactory) -> [Workflow])? = nil) -> WorkflowGroup {
    WorkflowGroup(id: id,
          name: name,
          color: "#fff",
          rule: rule ?? self.rule(id: id),
          workflows: workflows?(self) ?? [workflow(id: id)])
  }

  func keyboardCommand(id: String = UUID().uuidString, lhs: Bool) -> KeyboardCommand {
    .init(id: id, keyboardShortcut: keyboardShortcut(id: id, lhs: lhs))
  }

  func keyboardShortcut(id: String = UUID().uuidString,
                        key: String = "A",
                        lhs: Bool,
                        modifiers: [ModifierKey]? = nil) -> KeyShortcut {
    .init(id: id, key: key, lhs: lhs, modifiers: modifiers)
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
      .appleScript(id: id, isEnabled: true, name: nil, source: .inline(script)),
      .appleScript(id: id, isEnabled: true, name: nil, source: .path(path)),
      .shell(id: id, isEnabled: true, name: nil, source: .inline(script)),
      .shell(id: id, isEnabled: true, name: nil, source: .path(path))
    ]
  }

  func keyboardShortcut(_ modifiers: [ModifierKey], lhs: Bool) -> KeyShortcut {
    .init(key: "A", lhs: lhs, modifiers: modifiers)
  }

  func workflow(id: String = UUID().uuidString,
                keyboardShortcuts: ((ModelFactory) -> [KeyShortcut])? = nil,
                commands: ((ModelFactory) -> [Command])? = nil,
                name: String = "Open/active Finder") -> Workflow {
    Workflow(
      id: id,
      name: name,
      trigger: .keyboardShortcuts(keyboardShortcuts?(self) ??
                                  [keyboardShortcut(id: id, lhs: true, modifiers: [.control, .option])]),
      commands: commands?(self) ?? [.application(applicationCommand(id: id))])
  }
}

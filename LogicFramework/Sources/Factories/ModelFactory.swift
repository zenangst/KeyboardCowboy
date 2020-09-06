import Foundation

class ModelFactory {
  func application() -> Application {
    Application(bundleIdentifier: "com.apple.Finder",
                name: "Finder",
                path: "/System/Library/CoreServices/Finder.app")
  }

  func applicationCommand() -> ApplicationCommand {
    .init(application: application())
  }

  func days() -> [Day] {
    [.Monday, .Tuesday, .Wednesday, .Thursday, .Friday, .Saturday, .Sunday]
  }

  func group() -> Group {
    Group(name: "Global shortcuts",
          rules: rules(),
          workflows: [workflow()])
  }

  func keyboardCommand() -> KeyboardCommand {
    .init(output: "A")
  }

  func openCommand() -> OpenCommand {
    .init(application: application(), url: URL(string: "~/Desktop/new_real_final_draft_Copy_42.psd")!)
  }

  func rules() -> [Rule] {
    [.application(application()),
     .days(days())]
  }

  func scriptCommands() -> [ScriptCommand] {
    let path = URL(fileURLWithPath: "/tmp/file")
    let script = "#!/usr/bin/env fish"
    return [
      ScriptCommand(kind: .appleScript(.inline(script))),
      ScriptCommand(kind: .appleScript(.path(path))),
      ScriptCommand(kind: .shell(.inline(script))),
      ScriptCommand(kind: .shell(.path(path)))
    ]
  }

  func workflow() -> Workflow {
    let commands: [Command] = [
      .application(applicationCommand())
    ]
    return Workflow(commands: commands, name: "Open/active Finder")
  }
}

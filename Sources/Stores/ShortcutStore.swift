import Foundation

@MainActor
final class ShortcutStore: ObservableObject {
  let engine = ScriptEngine()
  @Published var shortcuts = [Shortcut]()

  init() {
    index()
  }

  func index() {
    let source = """
    shortcuts list
    """
    let script = ScriptCommand.shell(id: "ShortcutStore", isEnabled: true,
                                     name: "List shorcuts", source: .inline(source))

    Task {
      guard let result = try await engine.run(script) else {
        return
      }

      let lines = result.split(separator: "\n").compactMap(String.init)
      var shortcuts = [Shortcut]()
      for line in lines {
        if !shortcuts.contains(where: { $0.name == line }) {
          shortcuts.append(Shortcut(name: line))
        }
      }
      self.shortcuts = shortcuts.sorted(by: { $0.name < $1.name })
    }
  }
}

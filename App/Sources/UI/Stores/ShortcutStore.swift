import Cocoa

final class ShortcutStore: ObservableObject {
  @MainActor
  @Published private(set) var shortcuts = [Shortcut]()
  private let engine: ScriptEngine

  init(engine: ScriptEngine) {
    self.engine = engine
  }

  func index() {
    let source = """
    shortcuts list
    """
    let script = OldScriptCommand.shell(id: "ShortcutStore", isEnabled: true,
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
      let newShortcuts = shortcuts.sorted(by: { $0.name < $1.name })

      await MainActor.run {
        self.shortcuts = newShortcuts
      }
    }
  }
}

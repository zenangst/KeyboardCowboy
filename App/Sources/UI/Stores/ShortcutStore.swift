import Cocoa
import Combine

final class ShortcutStore: ObservableObject, @unchecked Sendable {
  @MainActor
  @Published private(set) var shortcuts = [Shortcut]()
  private let scriptCommandRunner: ScriptCommandRunner

  private var subscription: AnyCancellable?

  init(_ scriptCommandRunner: ScriptCommandRunner) {
    self.scriptCommandRunner = scriptCommandRunner
  }

  func subscribe(to application: Published<UserSpace.Application>.Publisher) {
    subscription = application
      .filter { $0.bundleIdentifier == "com.apple.shortcuts" }
      .sink { [weak self] _ in
        guard let self else { return }

        Task {
          await self.index()
        }
      }
  }

  func index() async {
    let shellScript = ScriptCommand(
      name: "List Shortcuts",
      kind: .shellScript,
      source: .inline("shortcuts list"),
    )

    do {
      let snapshot = await UserSpace.shared.snapshot(resolveUserEnvironment: true)
      guard let output = try await scriptCommandRunner.run(
        shellScript,
        snapshot: snapshot,
        runtimeDictionary: snapshot.terminalEnvironment(),
        checkCancellation: true,
      ) else {
        return
      }

      let shortcuts = output
        .split(separator: "\n")
        .sorted(by: { $0.lowercased() < $1.lowercased() })
        .compactMap { subString in
          let string = String(subString).trimmingCharacters(in: .whitespacesAndNewlines)
          return Shortcut(name: string)
        }
      await setShortcuts(shortcuts)
    } catch {
      print("Error indexing shortcuts: \(error)")
      await setShortcuts([])
    }
  }

  @MainActor
  private func setShortcuts(_ shortcuts: [Shortcut]) {
    self.shortcuts = shortcuts
  }
}

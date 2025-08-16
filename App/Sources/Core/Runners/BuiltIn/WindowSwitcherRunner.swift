final class WindowSwitcherRunner: Sendable {
  private let windowOpener: WindowOpener

  init(_ windowOpener: WindowOpener) {
    self.windowOpener = windowOpener
  }

  func run(_ snapshot: UserSpace.Snapshot) async -> String {
    await windowOpener.openWindowSwitcher(snapshot)
    return ""
  }
}

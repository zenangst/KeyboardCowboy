import Foundation

@MainActor
final class WindowTilingCommandRunner {
  private let centerFocus: WindowFocusCenter
  private let relativeFocus: WindowFocusRelativeFocus
  private let quarterFocus: WindowFocusQuarter

  init(centerFocus: WindowFocusCenter, relativeFocus: WindowFocusRelativeFocus, quarterFocus: WindowFocusQuarter) {
    self.centerFocus = centerFocus
    self.relativeFocus = relativeFocus
    self.quarterFocus = quarterFocus
  }

  func resetFocusComponents() {
    centerFocus.reset()
    quarterFocus.reset()
    relativeFocus.reset()
  }

  func run(_ command: WindowTilingCommand, snapshot: UserSpace.Snapshot) async throws {
    try await WindowTilingRunner.run(command.kind, snapshot: snapshot)
    resetFocusComponents()
  }
}

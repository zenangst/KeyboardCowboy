import ScriptingFeature

extension Operation {
  @MainActor
  struct ShowNotificationCenter {
    let executeScript: @MainActor (ScriptRequest) async throws -> String?

    func callAsFunction() async throws {
      _ = try await executeScript(.init(
        id: SystemCommand.Action.showNotificationCenter.rawValue,
        kind: .appleScript(.regular),
        source: .inline("""
          tell application "System Events"
            if exists action "AXToggleUI" of application process "NotificationCenter" then
              perform action "AXToggleUI" of application process "NotificationCenter"
            else
              click menu bar item 2 of menu bar 1 of application process "ControlCenter"
            end if
          end tell
          """),
      ))
    }
  }
}

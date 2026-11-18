import MachPortSystem

extension HostInput.TapSession {
  @MainActor
  struct Tap {
    let start: () throws -> Void
    let stop: () -> Void
    let reload: () throws -> Void
    let makePoster: () throws -> MachPortSystem.KeyboardEventPoster
  }
}

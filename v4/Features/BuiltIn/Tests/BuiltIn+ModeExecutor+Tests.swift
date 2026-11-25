import BuiltInFeature
import Testing

private struct Mode: Equatable {
  let id: String
  let name: String
  var isEnabled: Bool
}

@Test(arguments: [
  (BuiltIn.ModeAction.enable, false, true, "Mode ✅"),
  (.enable, true, true, "Mode ✅"),
  (.disable, true, false, "Mode ⏸️"),
  (.disable, false, false, "Mode ⏸️"),
  (.toggle, false, true, "Mode: ✅"),
  (.toggle, true, false, "Mode: ⏸️"),
])
@MainActor
func modeExecutorUpdatesOnlyTheMatchingLiveMode(
  action: BuiltIn.ModeAction, initiallyEnabled: Bool, expectedEnabled: Bool, expectedOutput: String,
) throws {
  let other = Mode(id: "other", name: "Shared name", isEnabled: true)
  let target = Mode(id: "target", name: "Shared name", isEnabled: initiallyEnabled)
  let last = Mode(id: "last", name: "Other name", isEnabled: false)
  var writes: [[Mode]] = []
  let executor = BuiltIn.ModeExecutor(id: \Mode.id, isEnabled: \.isEnabled,
                                     readModes: { [other, target, last] }, updateModes: { writes.append($0) })

  #expect(try executor.run(modeID: "target", commandName: "Mode", action: action) == expectedOutput)
  #expect(writes == [[other, Mode(id: target.id, name: target.name, isEnabled: expectedEnabled), last]])
}

@Test @MainActor func modeExecutorRejectsUnknownIDWithoutUpdating() {
  let executor = BuiltIn.ModeExecutor(id: \Mode.id, isEnabled: \.isEnabled,
                                     readModes: { [Mode(id: "stored", name: "Missing", isEnabled: false)] },
                                     updateModes: { _ in Issue.record("Unexpected mode update") })
  #expect(throws: BuiltIn.ModeError.unableToResolveMode) {
    try executor.run(modeID: "missing", commandName: "Missing", action: .toggle)
  }
}

@Test @MainActor func modeExecutorReadsLatestStateForEveryToggle() throws {
  var modes = [Mode(id: "target", name: "Mode", isEnabled: false)]
  let executor = BuiltIn.ModeExecutor(id: \Mode.id, isEnabled: \.isEnabled,
                                     readModes: { modes }, updateModes: { modes = $0 })

  #expect(try executor.run(modeID: "target", commandName: "Mode", action: .toggle) == "Mode: ✅")
  #expect(try executor.run(modeID: "target", commandName: "Mode", action: .toggle) == "Mode: ⏸️")
  #expect(modes.map(\.isEnabled) == [false])
}

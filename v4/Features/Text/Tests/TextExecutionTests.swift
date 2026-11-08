import Testing
import TextFeature

@Test @MainActor func dispatchesResolvedInputByMode() async throws {
  var calls: [TextExecution] = []
  let executor = TextExecutor(typing: { calls.append($0) }, instant: { calls.append($0) })
  let typing = TextExecution(input: "hello", mode: .typing, actions: [.insertEnter])
  let instant = TextExecution(input: "world")

  try await executor.run(typing)
  try await executor.run(instant)

  #expect(calls == [typing, instant])
}

@Test @MainActor func emptyInputDoesNotInvokeEitherInsertion() async throws {
  var calls = 0
  let executor = TextExecutor(typing: { _ in calls += 1 }, instant: { _ in calls += 1 })

  for mode in [TextExecution.Mode.typing, .instant] {
    try await executor.run(TextExecution(input: "", mode: mode, actions: [.insertEnter]))
  }
  #expect(calls == 0)
}

@Test @MainActor func insertionErrorsPropagate() async {
  enum Failure: Error { case insertion }
  let executor = TextExecutor(typing: { _ in throw Failure.insertion }, instant: { _ in })
  await #expect(throws: Failure.insertion) {
    try await executor.run(TextExecution(input: "x", mode: .typing))
  }
}

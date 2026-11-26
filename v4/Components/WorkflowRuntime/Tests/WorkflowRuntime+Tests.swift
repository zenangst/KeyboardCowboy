import ApplicationTriggers
import Commands
import Testing
import WorkflowRuntime

private typealias Step = WorkflowRuntime.Step<String>
private typealias Request = WorkflowRuntime.Request<String>
private typealias Executor = WorkflowRuntime.Executor<String, Int>
private enum ProbeError: Error { case failed }

private func step(_ id: String, enabled: Bool = true, delay: Double? = nil, variable: String? = nil) -> Step {
  .init(metadata: .init(delay: delay, id: id, isEnabled: enabled, variableName: variable), payload: id)
}

@Test @MainActor func applicationMatchRunsEnabledStepsWithSharedSnapshotAndOutputs() async throws {
  let bundle = "com.example.fixture"
  let matches = ApplicationTriggers.match(.runningApplications(previous: [], current: [bundle]), rules: [
    .init(workflowID: "capture", bundleIdentifier: bundle, contexts: [.launched]),
  ])
  let match = try #require(matches.first)
  let request = Request(
    workflowID: match.workflowID,
    origin: .applicationTrigger(bundleIdentifier: match.bundleIdentifier, context: match.context.rawValue),
    steps: [step("first", delay: 40, variable: "last"), step("disabled", enabled: false, delay: 20),
            step("second", delay: 0.5, variable: "last")],
  )
  var calls: [String] = []
  var delays: [Duration] = []
  let executor = Executor(sleep: {
    calls.append("sleep")
    delays.append($0)
  }, dispatch: { step, run, context in
    calls.append(step.payload)
    #expect(run.workflowID == "capture")
    #expect(run.origin == .applicationTrigger(bundleIdentifier: bundle, context: "launched"))
    #expect(run.steps.map(\.payload) == ["first", "second"])
    #expect(context.variables["seed"] == "untouched")
    if step.payload == "first" {
      #expect(context.snapshot == 10)
      #expect(context.variables["last"] == nil)
      return .init(snapshot: 11, output: "first output")
    }
    #expect(context.snapshot == 11)
    #expect(context.variables["last"] == "first output")
    return .init(snapshot: 12, output: "")
  })

  let result = try await executor.run(request, from: .init(snapshot: 10, variables: ["seed": "untouched"]))
  #expect(calls == ["first", "sleep", "second", "sleep"])
  #expect(delays == [.milliseconds(40), .microseconds(500)])
  #expect(result.context.snapshot == 12)
  #expect(result.context.variables == ["seed": "untouched", "last": ""])
  try #require(result.outcomes.count == 2)
  guard case .succeeded(let id, let output) = result.outcomes[0],
        case .succeeded(let secondID, let secondOutput) = result.outcomes[1] else {
    Issue.record("Expected two successful outcomes")
    return
  }

  #expect(id == "first" && output == "first output")
  #expect(secondID == "second" && secondOutput.isEmpty)
}

@Test @MainActor func ordinaryFailureIsReportedAndKeepsContextAndDelay() async throws {
  var calls: [String] = []
  let executor = Executor(sleep: {
    #expect($0 == .milliseconds(5))
    calls.append("sleep")
  }, dispatch: { step, _, context in
    calls.append(step.payload)
    if step.payload == "fails" { throw ProbeError.failed }
    #expect(context.snapshot == 1)
    #expect(context.variables == ["key": "old"])
    return .init(snapshot: 2, output: "new")
  })

  let request = Request(workflowID: "manual", origin: .manual,
                        steps: [step("fails", delay: 5, variable: "key"), step("next", variable: "key")])
  let result = try await executor.run(request, from: .init(snapshot: 1, variables: ["key": "old"]))

  #expect(calls == ["fails", "sleep", "next"])
  #expect(result.context.snapshot == 2 && result.context.variables == ["key": "new"])
  try #require(result.outcomes.count == 2)
  guard case .failed(let id, let error) = result.outcomes[0] else {
    Issue.record("Expected failure outcome")
    return
  }

  #expect(id == "fails")
  #expect(error as? ProbeError == .failed)
}

@Test @MainActor func abortPolicyStopsBeforeTheDelayAndLaterSteps() async {
  var calls: [String] = []
  let executor = Executor(failurePolicy: { step, error in
    #expect(error as? ProbeError == .failed)
    calls.append("policy:\(step.payload)")
    return .abort
  }, sleep: { _ in Issue.record("Unexpected sleep") },
  dispatch: { step, _, _ in
    calls.append(step.payload)
    throw ProbeError.failed
  })

  let request = Request(workflowID: "manual", origin: .manual, steps: [step("fail", delay: 5), step("next")])
  await #expect(throws: ProbeError.failed) { try await executor.run(request, from: .init(snapshot: 0)) }
  #expect(calls == ["fail", "policy:fail"])
}

@Test @MainActor func preCancelledRunDoesNotDispatch() async {
  let executor = Executor(dispatch: { _, _, context in
    Issue.record("Unexpected dispatch")
    return .init(snapshot: context.snapshot, output: "")
  })

  let request = Request(workflowID: "cancel", origin: .manual, steps: [step("first")])
  let task = Task { @MainActor in
    withUnsafeCurrentTask { $0?.cancel() }
    return try await executor.run(request, from: .init(snapshot: 0))
  }
  await #expect(throws: CancellationError.self) { try await task.value }
}

@Test(arguments: [false, true])
@MainActor func cancellationDuringDispatchBypassesFailurePolicy(throwsAfterCancelling: Bool) async {
  var calls: [String] = []
  let executor = Executor(failurePolicy: { _, _ in
    Issue.record("Cancellation must not reach failure policy")
    return .proceed
  }, sleep: { _ in Issue.record("Unexpected sleep") }, dispatch: { step, _, context in
    calls.append(step.payload)
    withUnsafeCurrentTask { $0?.cancel() }
    if throwsAfterCancelling { throw ProbeError.failed }
    return .init(snapshot: context.snapshot + 1, output: "output")
  })

  let request = Request(workflowID: "cancel", origin: .manual, steps: [step("first", delay: 5), step("next")])
  let task = Task { @MainActor in try await executor.run(request, from: .init(snapshot: 0)) }
  await #expect(throws: CancellationError.self) { try await task.value }
  #expect(calls == ["first"])
}

@Test @MainActor func cancellationFromTheClockStopsTheRun() async {
  var calls: [String] = []
  let executor = Executor(sleep: { _ in throw CancellationError() }, dispatch: { step, _, context in
    calls.append(step.payload)
    return .init(snapshot: context.snapshot, output: "")
  })
  let request = Request(workflowID: "cancel", origin: .manual, steps: [step("first", delay: 5), step("next")])
  await #expect(throws: CancellationError.self) { try await executor.run(request, from: .init(snapshot: 0)) }
  #expect(calls == ["first"])
}

@Test @MainActor func invalidDelaysDoNotSleep() async throws {
  let executor = Executor(
    sleep: { _ in Issue.record("Unexpected sleep") },
    dispatch: { _, _, context in
      .init(snapshot: context.snapshot + 1, output: "")
    })

  let delays = [-1.0, 0, .infinity, .nan, .greatestFiniteMagnitude]
  let request = Request(workflowID: "invalid-delays", origin: .manual, steps: delays.enumerated().map {
    step(String($0.offset), delay: $0.element)
  })
  let result = try await executor.run(request, from: .init(snapshot: 0))

  #expect(result.context.snapshot == delays.count)
}

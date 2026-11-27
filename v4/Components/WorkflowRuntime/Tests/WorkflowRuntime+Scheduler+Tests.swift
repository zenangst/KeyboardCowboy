import Commands
import Testing
import WorkflowRuntime

private typealias Scheduler = WorkflowRuntime.Scheduler<String, Int>
private typealias Request = WorkflowRuntime.Request<String>

private func request(_ id: String) -> Request {
  .init(workflowID: id, origin: .manual, steps: ["first", "second"].map {
    .init(metadata: .init(delay: 5, id: $0), payload: $0)
  })
}

@MainActor
final class DispatchGate {
  let started: AsyncStream<Void>
  private let signal: AsyncStream<Void>.Continuation
  private var resume: CheckedContinuation<Void, Never>?

  init() {
    (started, signal) = AsyncStream.makeStream()
  }

  func hold() async {
    await withCheckedContinuation {
      resume = $0
      signal.yield(())
      signal.finish()
    }
  }

  func open() {
    resume?.resume()
    resume = nil
  }
}

@Test @MainActor func concurrentReplacementKeepsStepsOrderedAndLeavesSerialRunning() async throws {
  let serialGate = DispatchGate()
  let oldGate = DispatchGate()
  let replacementGate = DispatchGate()
  var calls: [String: [String]] = [:]
  var delays: [Duration] = []
  let scheduler = Scheduler(executor: .init(sleep: { delays.append($0) }, dispatch: { step, run, context in
    calls[run.workflowID, default: []].append(step.payload)
    if step.payload == "first" {
      switch run.workflowID {
      case "serial": await serialGate.hold()
      case "old": await oldGate.hold()
      case "replacement": await replacementGate.hold()
      default: break
      }
    }
    return .init(snapshot: context.snapshot + 1, output: "")
  }))

  let serial = scheduler.start(request("serial"), from: .init(snapshot: 0))
  for await _ in serialGate.started {}
  let old = scheduler.start(request("old"), from: .init(snapshot: 0), lane: .concurrent)
  for await _ in oldGate.started {}
  let replacement = scheduler.start(request("replacement"), from: .init(snapshot: 0), lane: .concurrent)
  for await _ in replacementGate.started {}
  oldGate.open()
  await #expect(throws: CancellationError.self) { try await old.value }
  #expect(!serial.isCancelled)

  // Completing the old task must not discard the replacement's cancellation handle.
  let latest = scheduler.start(request("latest"), from: .init(snapshot: 0), lane: .concurrent)
  replacementGate.open()
  await #expect(throws: CancellationError.self) { try await replacement.value }
  let latestResult = try await latest.value
  #expect(latestResult.context.snapshot == 2)
  #expect(calls["old"] == ["first"])
  #expect(calls["replacement"] == ["first"])
  #expect(calls["latest"] == ["first", "second"])
  #expect(delays.isEmpty)

  serialGate.open()
  let serialResult = try await serial.value
  #expect(serialResult.context.snapshot == 2)
  #expect(calls["serial"] == ["first", "second"])
  #expect(delays == [.milliseconds(5), .milliseconds(5)])
}

@Test(arguments: [false, true])
@MainActor func cancellingBothLanesIncludesOverlappingSerialRuns(byStartingRun: Bool) async throws {
  let gates = ["a": DispatchGate(), "b": DispatchGate(), "c": DispatchGate()]
  let scheduler = Scheduler(executor: .init(sleep: { _ in }, dispatch: { step, run, context in
    if let gate = gates[run.workflowID] {
      #expect(step.payload == "first")
      if step.payload == "first" { await gate.hold() }
    }
    return .init(snapshot: context.snapshot + 1, output: "")
  }))

  var tasks: [Task<WorkflowRuntime.Result<Int>, any Error>] = []
  for id in ["a", "b", "c"] {
    let gate = try #require(gates[id])
    tasks.append(scheduler.start(request(id), from: .init(snapshot: 0), lane: id == "c" ? .concurrent : .serial))
    for await _ in gate.started {}
  }
  #expect(tasks.allSatisfy { !$0.isCancelled })
  let next: Task<WorkflowRuntime.Result<Int>, any Error>?
  if byStartingRun {
    next = scheduler.start(request("next"), from: .init(snapshot: 0), cancelPrevious: true)
  } else {
    scheduler.cancelAll()
    next = nil
  }
  for gate in gates.values { gate.open() }
  for task in tasks {
    await #expect(throws: CancellationError.self) { try await task.value }
  }
  if let next {
    let result = try await next.value
    #expect(result.context.snapshot == 2)
  }
}

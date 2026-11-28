import Commands
import Testing
import WorkflowRuntime

private typealias Executor = WorkflowRuntime.Executor<String, Int>
private typealias Request = WorkflowRuntime.Request<String>
private typealias Step = WorkflowRuntime.Step<String>

private func step(_ id: String, variable: String? = nil, delay: Double? = nil) -> Step {
  .init(metadata: .init(delay: delay, id: id, variableName: variable), payload: id)
}

private func request(_ id: String, _ steps: Step...) -> Request {
  .init(workflowID: id, origin: .manual, steps: steps)
}

@Test @MainActor func sharedChildrenPassSnapshotAndVariablesToSiblingsAndParent() async throws {
  var calls: [String] = []
  let child = request("child", step("increment", variable: "child"))
  let executor = Executor(dispatchingNested: { step, run, context, runChild in
    calls.append(step.payload)
    if run.workflowID == "child" {
      #expect(context.variables["seed"] == "parent")
      return .init(snapshot: context.snapshot + 1, output: String(context.snapshot))
    }
    if step.payload == "expand" {
      let first = try await runChild(child, .shared(context))
      #expect(first.context.variables["child"] == "10")
      let second = try await runChild(child, .shared(first.context))
      #expect(second.context.variables["child"] == "11")
      return .init(context: second.context, output: "expanded")
    }
    #expect(context.snapshot == 12)
    #expect(context.variables == ["seed": "parent", "child": "11", "expansion": "expanded"])
    return .init(snapshot: context.snapshot, output: "")
  })
  let result = try await executor.run(
    request("parent", step("expand", variable: "expansion"), step("after")),
    from: .init(snapshot: 10, variables: ["seed": "parent"]),
  )

  #expect(calls == ["expand", "increment", "increment", "after"])
  #expect(result.outcomes.count == 2)
  #expect(result.context.variables == ["seed": "parent", "child": "11", "expansion": "expanded"])
}

@Test @MainActor func isolatedChildrenStartFreshAndDoNotUpdateParentOrSiblingState() async throws {
  var snapshots: [Int] = []
  let child = request("child", step("capture", variable: "seed"))
  let executor = Executor(dispatchingNested: { step, run, context, runChild in
    if run.workflowID == "child" {
      #expect(context.variables.isEmpty)
      snapshots.append(context.snapshot)
      return .init(snapshot: context.snapshot + 1, output: "child")
    }
    if step.payload == "expand" {
      for freshSnapshot in [20, 30] {
        let result = try await runChild(child, .isolated(snapshot: freshSnapshot))
        #expect(result.context.snapshot == freshSnapshot + 1)
        #expect(result.context.variables["seed"] == "child")
      }
    } else {
      #expect(context.snapshot == 10)
      #expect(context.variables == ["seed": "parent"])
    }
    return .init(snapshot: context.snapshot, output: "")
  })
  let result = try await executor.run(
    request("parent", step("expand"), step("after")),
    from: .init(snapshot: 10, variables: ["seed": "parent"]),
  )

  #expect(snapshots == [20, 30])
  #expect(result.context.snapshot == 10)
  #expect(result.context.variables == ["seed": "parent"])
}

@Test @MainActor func nestedReentryFailsBeforeRedispatchingAnAncestor() async throws {
  var calls: [String] = []
  let parent = request("parent", step("expand"))
  let child = request("child", step("reenter"))
  let executor = Executor(failurePolicy: { _, _, _ in .abort }, dispatchingNested: { step, _, context, runChild in
    calls.append(step.payload)
    let result = try await runChild(step.payload == "expand" ? child : parent, .shared(context))
    return .init(context: result.context, output: "")
  })

  do {
    _ = try await executor.run(parent, from: .init(snapshot: 0))
    Issue.record("Expected nested re-entry to fail")
  } catch let error as WorkflowRuntime.ReentryError {
    #expect(error.workflowID == "parent")
  }
  #expect(calls == ["expand", "reenter"])
}

private enum ChildFailure: Error, Equatable { case script }

@Test(arguments: [WorkflowRuntime.Lane.serial, .concurrent])
@MainActor func nestedFailurePolicyReceivesTheParentLane(lane: WorkflowRuntime.Lane) async throws {
  var events: [String] = []
  let parent = request("parent", step("expand"), step("parent tail"))
  let child = request("child", step("script", delay: 5), step("child tail"))
  let executor = Executor(
    failurePolicy: { step, error, actualLane in
      #expect(actualLane == lane)
      #expect(error as? ChildFailure == .script)
      events.append("classify \(step.payload)")
      return actualLane == .serial ? .abort : .proceed
    },
    sleep: { _ in Issue.record("Neither an abort nor a concurrent step should sleep") },
    dispatchingNested: { step, _, context, runChild in
      events.append(step.payload)
      if step.payload == "script" { throw ChildFailure.script }
      if step.payload == "expand" {
        let result = try await runChild(child, .shared(context))
        guard case .failed(let id, let error) = result.outcomes.first else {
          Issue.record("Expected the child failure to be recorded separately")
          return .init(context: context, output: "")
        }
        #expect(id == "script" && error as? ChildFailure == .script)
        return .init(context: result.context, output: "")
      }
      return .init(snapshot: context.snapshot + 1, output: "")
    },
  )

  if lane == .serial {
    await #expect(throws: ChildFailure.script) { try await executor.run(parent, from: .init(snapshot: 0), lane: lane) }
    #expect(events == ["expand", "script", "classify script", "classify expand"])
  } else {
    let result = try await executor.run(parent, from: .init(snapshot: 0), lane: lane)
    #expect(result.context.snapshot == 2)
    #expect(events == ["expand", "script", "classify script", "child tail", "parent tail"])
  }
}

@Test(arguments: [false, true], [false, true])
@MainActor func bundledChildPolicyDelaysSuccessAndBubblesFailureInConcurrentLane(fails: Bool, shared: Bool) async throws {
  var events: [String] = []
  var delays: [Duration] = []
  let child = request("child", step("update", variable: "child value", delay: 5),
                      step("finish", delay: 10), step("child tail"))
  let executor = Executor(
    failurePolicy: { step, error, lane in
      #expect(lane == .concurrent && error as? ChildFailure == .script)
      events.append("classify \(step.payload)")
      return .proceed
    },
    sleep: { delays.append($0); events.append("delay") },
    dispatchingNested: { step, _, context, runChild in
      events.append(step.payload)
      switch step.payload {
      case "expand":
        let childContext: WorkflowRuntime.ChildContext<Int> = shared ? .shared(context) : .isolated(snapshot: 20)
        let result = try await runChild(child, childContext, policy: .delayAfterSuccessAndAbortOnFailure)
        return .init(context: shared ? result.context : context, output: "")
      case "update":
        #expect(context.snapshot == (shared ? 10 : 20))
        #expect(context.variables == (shared ? ["seed": "parent"] : [:]))
        return .init(snapshot: context.snapshot + 1, output: "updated")
      case "finish":
        #expect(context.variables["child value"] == "updated")
        if fails { throw ChildFailure.script }
      default: break
      }
      return .init(snapshot: context.snapshot, output: "")
    },
  )
  let result = try await executor.run(
    request("parent", step("expand", delay: 20), step("parent tail")),
    from: .init(snapshot: 10, variables: ["seed": "parent"]), lane: .concurrent,
  )

  #expect(result.context.snapshot == (shared ? 11 : 10))
  #expect(result.context.variables == (shared ? ["seed": "parent", "child value": "updated"] : ["seed": "parent"]))
  if fails {
    #expect(events == ["expand", "update", "delay", "finish", "classify expand", "parent tail"])
    #expect(delays == [.milliseconds(5)])
    guard case .failed(let id, let error) = result.outcomes.first else {
      Issue.record("Expected the parent step to receive the child failure")
      return
    }
    #expect(id == "expand" && error as? ChildFailure == .script)
  } else {
    #expect(events == ["expand", "update", "delay", "finish", "delay", "child tail", "parent tail"])
    #expect(delays == [.milliseconds(5), .milliseconds(10)])
  }
}

@Test(arguments: [false, true])
@MainActor func schedulerCancellationDuringChildUnwindsParentWithoutDispatchingLaterSteps(onTeardown: Bool) async throws {
  let gate = DispatchGate()
  var events: [String] = []
  let child = request("child", step("hold", delay: 5), step("unexpected child step"))
  let executor = Executor(
    failurePolicy: { _, _, _ in
      Issue.record("Cancellation reached the failure policy")
      return .abort
    },
    sleep: { _ in Issue.record("Unexpected delay") },
    dispatchingNested: { step, _, context, runChild in
      events.append(step.payload)
      if step.payload == "hold" {
        defer { events.append("child unwound") }
        await gate.hold()
        #expect(Task.isCancelled)
      } else if step.payload == "expand" {
        defer { events.append("parent unwound") }
        _ = try await runChild(child, .isolated(snapshot: 20))
        Issue.record("Cancelled child returned a result")
      }
      return .init(snapshot: context.snapshot, output: "")
    },
  )
  var scheduler: WorkflowRuntime.Scheduler? = .init(executor: executor)
  weak var retainedScheduler = scheduler
  let task = try #require(scheduler?.start(
    request("parent", step("expand"), step("unexpected parent step")), from: .init(snapshot: 10),
  ))
  for await _ in gate.started {}
  if onTeardown {
    scheduler = nil
    #expect(retainedScheduler == nil)
  } else {
    scheduler?.cancelAll()
  }
  #expect(task.isCancelled)
  gate.open()

  await #expect(throws: CancellationError.self) { try await task.value }
  #expect(events == ["expand", "hold", "child unwound", "parent unwound"])
}

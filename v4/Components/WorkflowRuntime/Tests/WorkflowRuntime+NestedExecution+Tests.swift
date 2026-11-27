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
  let executor = Executor(failurePolicy: { _, _ in .abort }, dispatchingNested: { step, _, context, runChild in
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

@Test @MainActor func schedulerCancellationDuringChildUnwindsParentWithoutDispatchingLaterSteps() async {
  let gate = DispatchGate()
  var events: [String] = []
  let child = request("child", step("hold", delay: 5), step("unexpected child step"))
  let executor = Executor(
    failurePolicy: { _, _ in
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
  let scheduler = WorkflowRuntime.Scheduler(executor: executor)
  let task = scheduler.start(request("parent", step("expand"), step("unexpected parent step")), from: .init(snapshot: 10))
  for await _ in gate.started {}
  scheduler.cancelAll()
  gate.open()

  await #expect(throws: CancellationError.self) { try await task.value }
  #expect(events == ["expand", "hold", "child unwound", "parent unwound"])
}

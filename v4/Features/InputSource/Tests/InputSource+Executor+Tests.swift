#if DEBUG
  import InputSourceFeature
  import InputSourceSystem
  import Testing

  private enum Failure: Error, Equatable { case current, lookup, select }

  @MainActor
  private final class Script {
    var calls: [String] = []
    var currentID = "current"
    var failure: Failure?
    var cancelDuringLookup = false

    var mock: InputSource.Controller.Mock {
      .init(
        current: {
          self.calls.append("current")
          if self.failure == .current { throw Failure.current }
          return InputSource.Controller.Testing.source(id: self.currentID, token: "current")
        },
        find: { id, includeAllInstalled in
          self.calls.append("find:\(id):\(includeAllInstalled)")
          if self.failure == .lookup { throw Failure.lookup }
          if self.cancelDuringLookup { withUnsafeCurrentTask { $0?.cancel() } }
          return InputSource.Controller.Testing.source(id: "target", token: "found")
        },
        select: { source in
          self.calls.append("select:\(source.testingToken ?? "live")")
          if self.failure == .select { throw Failure.select }
        }
      )
    }
  }

  private let request = InputSource.Request(id: "request", inputSourceId: "target", name: "Target")

  @MainActor private func executor() -> InputSource.Executor {
    InputSource.Executor(controller: .testing())
  }

  @Test @MainActor func liveExecutorCanBeConstructedByConsumer() {
    _ = InputSource.Executor()
  }

  @Test @MainActor func selectsExactLookupResult() async throws {
    let script = Script()
    try await InputSource.Controller.Testing.$mock.withValue(script.mock) {
      try await executor().run(request)
    }
    #expect(script.calls == ["current", "find:target:false", "select:found"])
  }

  @Test @MainActor func sourceIDsAreNotNormalized() async throws {
    let script = Script()
    script.currentID = "com.example.layout"
    let request = InputSource.Request(id: "request", inputSourceId: " Com.Example.Layout ", name: "ignored")
    try await InputSource.Controller.Testing.$mock.withValue(script.mock) {
      try await executor().run(request)
    }
    #expect(script.calls == ["current", "find: Com.Example.Layout :false", "select:found"])
  }

  @Test @MainActor func selectedSourceIsNoOpEvenWhenCancelled() async throws {
    let script = Script()
    script.currentID = "target"
    try await InputSource.Controller.Testing.$mock.withValue(script.mock) {
      let task = Task { @MainActor in
        withUnsafeCurrentTask { $0?.cancel() }
        try await executor().run(request)
      }
      try await task.value
    }
    #expect(script.calls == ["current"])
  }

  @Test @MainActor func cancellationStopsBeforeLookup() async {
    let script = Script()
    await InputSource.Controller.Testing.$mock.withValue(script.mock) {
      let task = Task { @MainActor in
        withUnsafeCurrentTask { $0?.cancel() }
        try await executor().run(request)
      }
      do { try await task.value; Issue.record("Expected cancellation") }
      catch is CancellationError {} catch { Issue.record("Unexpected error: \(error)") }
    }
    #expect(script.calls == ["current"])
  }

  @Test @MainActor func cancellationDuringLookupDoesNotAddAnotherCheckpoint() async throws {
    let script = Script()
    script.cancelDuringLookup = true
    try await InputSource.Controller.Testing.$mock.withValue(script.mock) {
      let task = Task { @MainActor in try await executor().run(request) }
      try await task.value
    }
    #expect(script.calls == ["current", "find:target:false", "select:found"])
  }

  @Test(arguments: [Failure.current, .lookup, .select]) @MainActor
  private func errorsPropagateWithoutFurtherCalls(failure: Failure) async {
    let script = Script()
    script.failure = failure
    await InputSource.Controller.Testing.$mock.withValue(script.mock) {
      do { try await executor().run(request); Issue.record("Expected error") }
      catch { #expect(error as? Failure == failure) }
    }
    switch failure {
    case .current: #expect(script.calls == ["current"])
    case .lookup: #expect(script.calls == ["current", "find:target:false"])
    case .select: #expect(script.calls == ["current", "find:target:false", "select:found"])
    }
  }

  @Test @MainActor func unconfiguredMocksFail() async {
    do { try await executor().run(request); Issue.record("Expected unconfigured mock error") }
    catch is InputSource.Controller.Mock.Unconfigured {} catch { Issue.record("Unexpected error: \(error)") }
  }

  @Test @MainActor func eachUnconfiguredOperationFails() throws {
    let controller = InputSource.Controller.testing()
    let source = InputSource.Controller.Testing.source(id: "target", token: "found")
    #expect(throws: InputSource.Controller.Mock.Unconfigured.self) { try controller.currentInputSource() }
    #expect(throws: InputSource.Controller.Mock.Unconfigured.self) { try controller.findInput("target", includeAllInstalled: false) }
    #expect(throws: InputSource.Controller.Mock.Unconfigured.self) { try controller.select(source) }
  }

  @Test @MainActor func mockOverridesAreScoped() async throws {
    let script = Script()
    script.currentID = "target"
    try await InputSource.Controller.Testing.$mock.withValue(script.mock) {
      try await executor().run(request)
    }
    #expect(script.calls == ["current"])
    do { try await executor().run(request); Issue.record("Expected restored default mock") }
    catch is InputSource.Controller.Mock.Unconfigured {} catch { Issue.record("Unexpected error: \(error)") }
  }
#endif

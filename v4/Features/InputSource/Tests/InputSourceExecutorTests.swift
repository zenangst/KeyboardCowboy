import InputSourceFeature
import Testing

private enum Failure: Error, Equatable { case current, lookup, select }

@MainActor
private final class Controller: InputSourceControlling {
  struct Source { let id: String; let token: Int }
  var calls: [String] = []
  var current = Source(id: "current", token: 1)
  var found = Source(id: "target", token: 2)
  var failure: Failure?

  func currentInputSource() throws -> Source {
    calls.append("current")
    if failure == .current { throw Failure.current }
    return current
  }
  func id(of source: Source) -> String { source.id }
  func findInput(_ id: String, includeAllInstalled: Bool) throws -> Source {
    calls.append("find:\(id):\(includeAllInstalled)")
    if failure == .lookup { throw Failure.lookup }
    return found
  }
  func select(_ source: Source) throws {
    calls.append("select:\(source.token)")
    if failure == .select { throw Failure.select }
  }
}

private let request = InputSourceRequest(id: "request", inputSourceId: "target", name: "Target")

@Test @MainActor func selectsExactLookupResult() async throws {
  let controller = Controller()
  try await InputSourceExecutor(controller: controller).run(request)
  #expect(controller.calls == ["current", "find:target:false", "select:2"])
}

@Test @MainActor func selectedSourceIsNoOpEvenWhenCancelled() async throws {
  let controller = Controller()
  controller.current = .init(id: "target", token: 1)
  let task = Task { @MainActor in
    withUnsafeCurrentTask { $0?.cancel() }
    try await InputSourceExecutor(controller: controller).run(request)
  }
  try await task.value
  #expect(controller.calls == ["current"])
}

@Test @MainActor func cancellationStopsBeforeLookup() async {
  let controller = Controller()
  let task = Task { @MainActor in
    withUnsafeCurrentTask { $0?.cancel() }
    try await InputSourceExecutor(controller: controller).run(request)
  }
  do { try await task.value; Issue.record("Expected cancellation") }
  catch is CancellationError {} catch { Issue.record("Unexpected error: \(error)") }
  #expect(controller.calls == ["current"])
}

@Test(arguments: [Failure.current, .lookup, .select]) @MainActor
private func errorsPropagateWithoutFurtherCalls(failure: Failure) async {
  let controller = Controller()
  controller.failure = failure
  do {
    try await InputSourceExecutor(controller: controller).run(request)
    Issue.record("Expected error")
  } catch {
    #expect(error as? Failure == failure)
  }
  switch failure {
  case .current: #expect(controller.calls == ["current"])
  case .lookup: #expect(controller.calls == ["current", "find:target:false"])
  case .select: #expect(controller.calls == ["current", "find:target:false", "select:2"])
  }
}

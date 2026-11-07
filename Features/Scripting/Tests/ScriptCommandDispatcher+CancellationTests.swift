import ScriptingFeature
import Testing

private actor ScriptRouteGate {
  private var parked: CheckedContinuation<Void, Never>?
  private var arrival: CheckedContinuation<Void, Never>?

  func suspend() async {
    await withCheckedContinuation { continuation in
      parked = continuation
      arrival?.resume()
      arrival = nil
    }
  }

  func waitForArrival() async {
    if parked != nil { return }
    await withCheckedContinuation { arrival = $0 }
  }

  func release() {
    parked?.resume()
    parked = nil
  }
}

private enum TestRouteError: Error { case failure }

@Test(arguments: [false, true])
func dispatcherCancellationAfterSuspendedRouteOverridesItsResult(fails: Bool) async {
  let gate = ScriptRouteGate()
  let routes = ScriptCommandDispatcher.Routes(
    appleScriptInline: { _, _ in
      await gate.suspend()
      if fails { throw TestRouteError.failure }
      return "finished"
    },
    appleScriptFile: { _, _ in nil }, jxaInline: { _ in nil },
    shellInline: { _ in nil }, shellFile: { _ in nil }, clearAppleScriptCache: {})
  let dispatcher = ScriptCommandDispatcher(routes: routes)
  await withTaskGroup(of: Bool.self) { group in
    group.addTask {
      do {
        _ = try await dispatcher.execute(.init(id: "id", kind: .appleScript(.regular), source: .inline("source")))
        return false
      } catch is CancellationError { return true }
      catch { Issue.record("Unexpected error: \(error)"); return false }
    }
    await gate.waitForArrival()
    group.cancelAll()
    await gate.release()
    #expect(await group.next() == true)
  }
}

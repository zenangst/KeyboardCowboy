import CowboyCore
import ScriptingFeature
import Testing

private enum RouteError: Error, Equatable { case failure }

private func routes() -> ScriptCommandDispatcher.Routes {
  .init(
    appleScriptInline: { "apple-inline:\($0):\($1)" },
    appleScriptFile: { "apple-file:\($0):\($1)" },
    jxaInline: { "jxa:\($0)" },
    shellInline: { "shell-inline:\($0)" },
    shellFile: { "shell-file:\($0)" },
    clearAppleScriptCache: {}
  )
}

@Test func publicDispatcherRoutesEveryCombination() async throws {
  let dispatcher = ScriptCommandDispatcher(routes: routes())
  let interpolation = ScriptInterpolation([
    .init(token: "$A", value: "$B"),
    .init(token: "$B", value: "value"),
  ])
  let cases: [(ScriptRequest.Kind, ScriptRequest.Source, String)] = [
    (.appleScript(.regular), .inline("$A $UNKNOWN"), "apple-inline:value $UNKNOWN:id"),
    (.appleScript(.jxa), .inline("$A"), "jxa:value"),
    (.appleScript(.regular), .path("/tmp/$A"), "apple-file:/tmp/$A:id"),
    (.appleScript(.jxa), .path("/tmp/$A"), "apple-file:/tmp/$A:id"),
    (.shellScript, .inline("$A"), "shell-inline:value"),
    (.shellScript, .path("/tmp/$A"), "shell-file:/tmp/value"),
  ]
  for (kind, source, expected) in cases {
    let result = try await dispatcher.execute(.init(id: "id", kind: kind, source: source), interpolation: interpolation)
    #expect(result == expected)
  }
}

@Test func publicDispatcherPreservesNilAndErrors() async throws {
  var injected = routes()
  injected.jxaInline = { _ in nil }
  injected.shellFile = { _ in throw RouteError.failure }
  let dispatcher = ScriptCommandDispatcher(routes: injected)
  let result = try await dispatcher.execute(.init(id: "x", kind: .appleScript(.jxa), source: .inline("")))
  #expect(result == nil)
  await #expect(throws: RouteError.failure) {
    try await dispatcher.execute(.init(id: "x", kind: .shellScript, source: .path("x")))
  }
}

@Test @MainActor func publicDispatcherProductionConstruction() async {
  let dispatcher = ScriptCommandDispatcher(.production)
  await dispatcher.clearAppleScriptCache()
}

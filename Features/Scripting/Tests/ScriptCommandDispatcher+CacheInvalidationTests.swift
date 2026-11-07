import ScriptingFeature
import Testing

@Test func dispatcherForwardsExplicitCacheInvalidation() async {
  let (events, continuation) = AsyncStream<String>.makeStream()
  let routes = ScriptCommandDispatcher.Routes(
    appleScriptInline: { _, _ in continuation.yield("inline"); return nil },
    appleScriptFile: { _, _ in continuation.yield("file"); return nil },
    jxaInline: { _ in continuation.yield("jxa"); return nil },
    shellInline: { _ in continuation.yield("shell"); return nil },
    shellFile: { _ in continuation.yield("shell-file"); return nil },
    clearAppleScriptCache: { continuation.yield("clear") })
  let dispatcher = ScriptCommandDispatcher(routes: routes)
  await dispatcher.clearAppleScriptCache()
  continuation.finish()
  var observed: [String] = []
  for await event in events { observed.append(event) }
  #expect(observed == ["clear"])
}

import CowboyCore
import ScriptingFeature
import Testing

@Test @MainActor func consumerCanConstructAndClearAppleScriptExecutor() async {
  let executor = AppleScript.Executor(.production)
  executor.clearCache()
}

@testable import ScriptingFeature
import Testing

@Test func inlineShellPreservesQuotingSemicolonsAndNewlines() throws {
  let source = "/usr/bin/printf '%s' 'a;b'; printf '%s' '-two'\nprintf '%s' '-three'"
  let processes = try ShellScript.Builder(.production).build(source)
  #expect(processes.count == 1)
  #expect(try ShellScript.Executor(.production).execute(processes) == "a;b-two-three")
}

@Test func nonexistentExecutableDoesNotDiscardFollowingShellCommand() throws {
  let source = "/definitely-not-a-real-executable-12345; printf '%s' 'continued'"
  let processes = try ShellScript.Builder(.production).build(source)
  #expect(processes.count == 1)
  #expect(try ShellScript.Executor(.production).execute(processes) == "continued")
}

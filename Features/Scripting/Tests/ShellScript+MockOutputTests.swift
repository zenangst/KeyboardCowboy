@testable import CowboyCore
import Foundation
@testable import ScriptingFeature
import Testing

private enum MockReadError: Error { case failed }

@Test(arguments: ["empty", "invalid", "nil", "failure"])
func scriptedProcessStreamsAreIndependent(route: String) async throws {
  let (events, continuation) = AsyncStream<String>.makeStream()
  let process = ShellScript.Builder(.testing).buildExecutable(
    at: URL(fileURLWithPath: "/bin/echo"), arguments: [])
  let mock = Core.Process.Mock(
    run: { continuation.yield("run") },
    waitUntilExit: { continuation.yield("wait") },
    readStandardOutput: {
      continuation.yield("stdout")
      switch route {
      case "empty": return Data()
      case "invalid": return Data([0xff])
      case "nil": return nil
      default: throw MockReadError.failed
      }
    },
    readStandardError: { continuation.yield("stderr"); return Data("diagnostic".utf8) })

  try Core.Process.Testing.$mock.withValue(mock) {
    if route == "failure" {
      #expect(throws: MockReadError.failed) { try ShellScript.Executor(.testing).execute(process) }
    } else {
      let output = try ShellScript.Executor(.testing).execute(process)
      #expect(output == (route == "empty" ? "" : "diagnostic"))
    }
  }
  continuation.finish()
  var observed: [String] = []
  for await event in events { observed.append(event) }
  #expect(observed == (route == "failure" ? ["run", "stdout"] : ["run", "stdout", "stderr", "wait"]))
}

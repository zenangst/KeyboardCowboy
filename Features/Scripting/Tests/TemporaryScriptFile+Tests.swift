@testable import CowboyCore
import Foundation
@testable import ScriptingFeature
import Testing

private enum TemporaryScriptEvent: Equatable, Sendable {
  case directory
  case create(String, Data?)
  case run
  case remove(String)
}

@Test(arguments: [false, true], [false, true])
func temporaryScriptFileLifecycle(jxa: Bool, creationSucceeds: Bool) async throws {
  let directory = URL(fileURLWithPath: "/tmp/script test directory", isDirectory: true)
  let source = "print('hello')"
  let scriptPath = directory.appendingPathComponent(jxa ? "script.js" : "script").path
  let (events, continuation) = AsyncStream<TemporaryScriptEvent>.makeStream()

  try Core.FileManager.Testing.$mock.withValue(.init(
    createDirectoryAtUrl: {
      continuation.yield(.directory)
      return directory
    },
    createFileAtPath: { path, data in
      continuation.yield(.create(path, data))
      return creationSucceeds
    },
    removeItemAtPath: { path in continuation.yield(.remove(path)) }
  )) {
    try Core.Process.Testing.$mock.withValue(.init(run: { continuation.yield(.run) })) {
      func execute() throws {
        if jxa {
          _ = try JXA.Executor(.testing).execute(source)
        } else {
          _ = try ShellScript.Executor(.testing).execute(ShellScript.Builder(.testing).build(source))
        }
      }

      if creationSucceeds {
        try execute()
      } else if jxa {
        #expect(throws: JXA.Error.self) { try execute() }
      } else {
        #expect(throws: ShellScript.Executor.Error.createFileFailed) { try execute() }
      }
    }
  }

  continuation.finish()
  var observed: [TemporaryScriptEvent] = []
  for await event in events { observed.append(event) }
  var expected: [TemporaryScriptEvent] = [.directory, .create(scriptPath, Data(source.utf8))]
  if creationSucceeds { expected.append(.run) }
  expected.append(.remove(directory.path))
  #expect(observed == expected)
}

import FileSystem
import CowboyCore
import Foundation
import ScriptingFeature
import Testing

@Test @MainActor func publicDispatcherExecutesInterpolatedShellFile() async throws {
  let directory = Foundation.FileManager.default.temporaryDirectory
    .appendingPathComponent("script dispatch \(UUID().uuidString)", isDirectory: true)
  try Foundation.FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
  defer { try? Foundation.FileManager.default.removeItem(at: directory) }
  let file = directory.appendingPathComponent("file with spaces.sh")
  try "#!/bin/sh\nprintf 'file output'".write(to: file, atomically: true, encoding: .utf8)

  let dispatcher = ScriptCommandDispatcher(.production)
  let command = ScriptRequest(id: "file", kind: .shellScript, source: .path("$SCRIPT_PATH"))
  let output = try await dispatcher.execute(command, interpolation: .init([
    .init(token: "$SCRIPT_PATH", value: file.path),
  ]))
  #expect(output == "file output")
  #expect(Foundation.FileManager.default.fileExists(atPath: file.path))
}

@Test @MainActor func publicDispatcherExposesSubprocessFailure() async throws {
  let dispatcher = ScriptCommandDispatcher(.production)
  let command = ScriptRequest(id: "failure", kind: .shellScript,
                              source: .inline("#!/bin/sh\nprintf message >&2; exit 17"))
  do {
    _ = try await dispatcher.execute(command)
    Issue.record("Expected a subprocess failure")
  } catch let failure as ScriptProcessError {
    #expect(failure.status == 17)
    #expect(failure.reason == .exit)
    #expect(failure.stderr == Data("message".utf8))
  }
}

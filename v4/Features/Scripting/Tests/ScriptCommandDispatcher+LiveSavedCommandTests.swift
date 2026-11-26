import Commands
import Foundation
import ScriptingFeature
import Testing

@Test @MainActor func savedScriptsExecuteThroughProductionDispatcher() async throws {
  struct Envelope: Decodable {
    let scriptCommand: Command.Script
  }

  let files = FileManager.default
  let directory = files.temporaryDirectory.appendingPathComponent("saved script fixtures \(UUID())", isDirectory: true)
  try files.createDirectory(at: directory, withIntermediateDirectories: false)
  defer {
    do { try files.removeItem(at: directory) } catch { Issue.record("Could not remove the script fixtures: \(error)") }
    #expect(!files.fileExists(atPath: directory.path))
  }
  let appleFile = directory.appendingPathComponent("sample script.applescript")
  let shellFile = directory.appendingPathComponent("sample script.sh")
  try #"return "apple file""#.write(to: appleFile, atomically: true, encoding: .utf8)
  try "#!/bin/sh\nprintf 'shell file'".write(to: shellFile, atomically: true, encoding: .utf8)

  let regular = ["appleScript": ["variant": ["regular": [String: String]()]]]
  let jxa = ["appleScript": ["variant": ["jxa": [String: String]()]]]
  let shell = ["shellScript": [String: String]()]
  let fixtures: [(kind: Any, source: String, contents: String, output: String)] = [
    (regular, "inline", #"return "apple inline""#, "apple inline"),
    ("scpt", "path", appleFile.path, "apple file"),
    (shell, "inline", "#!/bin/sh\nprintf 'shell inline'", "shell inline"),
    ("sh", "path", shellFile.path, "shell file"),
    (jxa, "inline", "'jxa inline'", "jxa inline\n"),
  ]
  let dispatcher = ScriptCommandDispatcher(.production)
  for (index, fixture) in fixtures.enumerated() {
    let data = try JSONSerialization.data(withJSONObject: [
      "scriptCommand": [
        "kind": fixture.kind,
        "source": [fixture.source: ["_0": fixture.contents]],
        "meta": ["id": "smoke-\(index)", "name": "Smoke fixture", "enabled": true],
      ],
    ])
    let command = try JSONDecoder().decode(Envelope.self, from: data).scriptCommand
    do {
      let output = try await dispatcher.execute(command)
      #expect(output == fixture.output)
    } catch {
      Issue.record("Fixture \(fixture.output) failed: \(error)")
    }
  }
}

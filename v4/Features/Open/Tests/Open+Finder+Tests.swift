import Foundation
import OpenFeature
import Testing

private actor ScriptRecorder {
  var scripts: [(String, String, Bool)] = []
  func record(_ name: String, _ source: String, _ cancellation: Bool) {
    scripts.append((name, source, cancellation))
  }
}

@Test func finderBuildsEscapedScriptAndForwardsCancellation() async throws {
  let recorder = ScriptRecorder()
  let finder = Open.Finder { await recorder.record($0, $1, $2) }
  let path = "/tmp/a\"b\\c"
  try await finder.open(path, checkCancellation: true)
  let scripts = await recorder.scripts
  #expect(scripts.count == 1)
  #expect(scripts[0].0 == "Open folder in Finder: \(path)")
  #expect(scripts[0].1 == """
  tell application "Finder"
    set the target of the front Finder window to folder ("/tmp/a\\\"b\\\\c" as POSIX file)
  end tell
  """)
  #expect(scripts[0].2)
}

@Test func finderChecksCancellationOnlyWhenRequested() async throws {
  let recorder = ScriptRecorder()
  let finder = Open.Finder { await recorder.record($0, $1, $2) }
  let task = Task {
    withUnsafeCurrentTask { $0?.cancel() }
    await #expect(throws: CancellationError.self) { try await finder.open("/tmp", checkCancellation: true) }
    try await finder.open("/tmp", checkCancellation: false)
  }
  try await task.value
  let scripts = await recorder.scripts
  #expect(scripts.count == 1)
  #expect(!scripts[0].2)
}

@Test func finderPropagatesScriptFailure() async {
  enum Failure: Error { case script }
  let finder = Open.Finder { _, _, _ in throw Failure.script }
  await #expect(throws: Failure.self) { try await finder.open("/tmp", checkCancellation: false) }
}

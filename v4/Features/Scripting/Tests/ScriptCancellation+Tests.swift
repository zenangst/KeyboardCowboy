@testable import FileSystem
@testable import ProcessSystem
@testable import CowboyCore
import Darwin
import Foundation
@testable import ScriptingFeature
import Testing

@Test func cancellationBeforeLaunchAndForEmptySequence() async throws {
  let task = Task {
    withUnsafeCurrentTask { $0?.cancel() }
    let executor = ShellScript.Executor(.testing)
    #expect(throws: CancellationError.self) { try executor.execute([]) }
    #expect(throws: CancellationError.self) { try JXA.Executor(.testing).execute("source") }
  }
  await task.value
}

@Test(arguments: [false, true])
func cancellationCleansInlineTemporaryDirectory(jxa: Bool) async throws {
  let marker = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  defer { try? FileManager.default.removeItem(at: marker) }
  let task = Task {
    Core.FileManager.Testing.$mock.withValue(.init(createFile: true, removeItem: {
      try Data().write(to: marker)
      throw CocoaError(.fileWriteUnknown)
    })) {
      Core.Process.Testing.$mock.withValue(.init(run: {
        withUnsafeCurrentTask { $0?.cancel() }
      })) {
        #expect(throws: CancellationError.self) {
          if jxa {
            _ = try JXA.Executor(.testing).execute("source")
          } else {
            let processes = try ShellScript.Builder(.testing).build("echo source")
            _ = try ShellScript.Executor(.testing).execute(processes)
          }
        }
      }
    }
  }
  _ = await task.value
  #expect(FileManager.default.fileExists(atPath: marker.path))
}

@Test(arguments: [false, true])
func cancellationAfterTemporaryDirectoryCreationCleansUp(jxa: Bool) async {
  let (events, continuation) = AsyncStream<String>.makeStream()
  let result = await Task {
    Core.FileManager.Testing.$mock.withValue(.init(
      createDirectoryAtUrl: {
        withUnsafeCurrentTask { $0?.cancel() }
        return URL(fileURLWithPath: "/tmp/cancelled-script-test")
      },
      createFile: false,
      removeItem: { continuation.yield("cleanup") }
    )) {
      do {
        if jxa {
          _ = try JXA.Executor(.testing).execute("source")
        } else {
          _ = try ShellScript.Executor(.testing).execute(ShellScript.Builder(.testing).build("source"))
        }
        return false
      } catch is CancellationError { return true }
      catch { Issue.record("Unexpected error: \(error)"); return false }
    }
  }.value
  continuation.finish()
  var observed: [String] = []
  for await event in events { observed.append(event) }
  #expect(result)
  #expect(observed == ["cleanup"])
}

@Test func cancellationAfterWaitWinsOverFailedExitAndStopsSequence() async {
  let task = Task {
    let builder = ShellScript.Builder(.testing)
    let process = builder.buildExecutable(at: URL(fileURLWithPath: "/bin/false"), arguments: [])
    Core.Process.Testing.$mock.withValue(.init(
      run: {},
      waitUntilExit: { withUnsafeCurrentTask { $0?.cancel() } },
      terminationStatus: 1
    )) {
      #expect(throws: CancellationError.self) {
        try ShellScript.Executor(.testing).execute([process, process])
      }
    }
  }
  await task.value
}

@Test(arguments: [false, true])
func cancellationReapsRunningDirectChild(closedPipes: Bool) async throws {
  // Run under an external watchdog: a regression can block task completion.
  guard ProcessInfo.processInfo.environment["RUN_SCRIPT_CANCELLATION_REGRESSION"] == "1" else { return }
  let pidFile = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  defer { try? FileManager.default.removeItem(at: pidFile) }
  let task = Task {
    let source = (closedPipes ? "close STDOUT; close STDERR; " : "")
      + "open(my $f, '>', $ARGV[0]) or die $!; print $f $$; close $f; sleep 30"
    let process = Core.Process(.production, launchStyle: .headless(source))
    process.executableURL = URL(fileURLWithPath: "/usr/bin/perl")
    process.arguments = ["-e", source, pidFile.path]
    return try ShellScript.Executor(.production).execute(process)
  }
  var pid: Int32?
  for _ in 0..<500 {
    if let text = try? String(contentsOf: pidFile, encoding: .utf8), let value = Int32(text) {
      pid = value
      break
    }
    try await Task.sleep(for: .milliseconds(10))
  }
  guard let pid else {
    task.cancel()
    _ = try? await task.value
    Issue.record("Child did not publish its PID")
    return
  }
  let start = ContinuousClock.now
  task.cancel()
  do {
    _ = try await task.value
    Issue.record("Expected cancellation")
  } catch is CancellationError {
    #expect(start.duration(to: .now) < .seconds(4))
  } catch {
    Issue.record("Expected CancellationError, got \(error)")
  }
  #expect(kill(pid, 0) == -1 && errno == ESRCH)
}

@Test func cancellationWhileQueuedAtDispatcherDoesNotLaunch() async throws {
  let started = DispatchSemaphore(value: 0)
  let release = DispatchSemaphore(value: 0)
  let routes = ScriptCommandDispatcher.Routes(
    appleScriptInline: { _, _ in nil }, appleScriptFile: { _, _ in nil },
    jxaInline: { try JXA.Executor(.testing).execute($0).0 },
    shellInline: { source in
      if source == "block" {
        started.signal()
        _ = release.wait(timeout: .now() + 5)
        return nil
      }
      return try ShellScript.Executor(.testing).execute(ShellScript.Builder(.testing).build(source))
    },
    shellFile: { try ShellScript.Executor(.testing).executeFile(at: $0) },
    clearAppleScriptCache: {}
  )
  let dispatcher = ScriptCommandDispatcher(routes: routes)
  let first = Task { try await dispatcher.execute(.init(id: "1", kind: .shellScript, source: .inline("block"))) }
  func didStart() -> Bool { started.wait(timeout: .now()) == .success }
  var ready = false
  for _ in 0..<500 {
    if didStart() { ready = true; break }
    try await Task.sleep(for: .milliseconds(10))
  }
  guard ready else {
    release.signal()
    _ = try? await first.value
    Issue.record("Dispatcher did not start")
    return
  }
  let second = Task { try await dispatcher.execute(.init(id: "2", kind: .shellScript, source: .inline("echo queued"))) }
  second.cancel()
  release.signal()
  _ = try await first.value
  do {
    _ = try await second.value
    Issue.record("Expected queued request to be cancelled")
  } catch is CancellationError {
  } catch {
    Issue.record("Expected CancellationError, got \(error)")
  }
}

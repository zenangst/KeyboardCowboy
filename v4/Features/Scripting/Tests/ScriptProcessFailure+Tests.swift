import FileSystem
import ProcessSystem
import CowboyCore
import Darwin
import Foundation
@testable import ScriptingFeature
import System
import Testing

private func runProcess(_ source: String) throws -> String? {
  let process = Core.Process(.production, launchStyle: .headless(source))
  process.executableURL = URL(fileURLWithPath: "/bin/sh")
  process.arguments = ["-c", source]
  return try ShellScript.Executor(.production).execute(process)
}

@Test func successfulProcessStillPrefersAndCleansStdout() throws {
  #expect(try runProcess("printf '\\033[31mhello\\033[0m'; printf ignored >&2") == "hello")
  #expect(try runProcess("printf ignored >&2") == "")
}

@Test func failedProcessRetainsBothStreams() throws {
  do {
    _ = try runProcess("printf output; printf diagnostic >&2; exit 23")
    Issue.record("Expected a subprocess failure")
  } catch let error as ScriptProcessError {
    #expect(error.status == 23)
    #expect(error.reason == .exit)
    #expect(error.stdout == Data("output".utf8))
    #expect(error.stderr == Data("diagnostic".utf8))
    #expect(error.localizedDescription.contains("status 23"))
    #expect(error.localizedDescription.contains("diagnostic"))
  }
}

@Test func signalTerminationIsReported() throws {
  do {
    _ = try runProcess("printf before; kill -TERM $$")
    Issue.record("Expected a subprocess failure")
  } catch let error as ScriptProcessError {
    #expect(error.reason == .signal)
    #expect(error.status == SIGTERM)
    #expect(error.stdout == Data("before".utf8))
    #expect(error.localizedDescription.contains("signal"))
  }
}

@Test func inlineAndFileShellFailuresPropagate() throws {
  let source = "#!/bin/sh\nprintf inline; printf problem >&2; exit 19"
  let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".sh")
  try source.write(to: file, atomically: true, encoding: .utf8)
  defer { try? FileManager.default.removeItem(at: file) }
  for run in [
    { try ShellScript.Executor(.production).execute(ShellScript.Builder(.production).build(source)) },
    { try ShellScript.Executor(.production).executeFile(at: file.path) },
  ] {
    do {
      _ = try run()
      Issue.record("Expected a shell failure")
    } catch let error as ScriptProcessError {
      #expect(error.status == 19)
      #expect(error.stdout == Data("inline".utf8))
      #expect(error.stderr == Data("problem".utf8))
    }
  }
}

@Test func jxaInlineAndFileFailuresPropagate() throws {
  let source = "throw new Error('intentional JXA failure')"
  let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".js")
  try source.write(to: file, atomically: true, encoding: .utf8)
  defer { try? FileManager.default.removeItem(at: file) }
  for run in [
    { try JXA.Executor(.production).execute(source) },
    { try JXA.Executor(.production).execute(FilePath(file.path)) },
  ] {
    do {
      _ = try run()
      Issue.record("Expected a JXA failure")
    } catch let error as ScriptProcessError {
      #expect(error.status != 0)
      #expect(!error.stderr.isEmpty)
      #expect(String(decoding: error.stderr, as: UTF8.self).contains("intentional JXA failure"))
    }
  }
}

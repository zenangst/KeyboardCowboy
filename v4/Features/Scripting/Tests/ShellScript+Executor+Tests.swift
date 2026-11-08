@testable import FileSystem
@testable import ProcessSystem
@testable import CowboyCore
import Foundation
import Darwin
@testable import ScriptingFeature
import Testing

final class TestResults: @unchecked Sendable {
  var didRun: Bool = false
  var didWaitUntilExit: Bool = false
  var didCreateDirectory: Bool = false
  var didRemoveDirectory: Bool = false
}

enum ExecutorTestError: Error {
  case launch, cleanup
}

@Test func testExecutationHeadless() throws {
  let builder = ShellScript.Builder(.testing)
  let script = [builder.buildExecutable(at: URL(filePath: "/bin/ls"), arguments: ["-la"])]
  let executor = ShellScript.Executor(.testing)
  let results = TestResults()

  try Core.FileManager.Testing.$mock.withValue(
    .init(
      contentsAtPath: nil,
      createDirectoryAtUrl: {
        return URL(filePath: "/tmp/testExecutationShell")
      },
      createFile: false,
      removeItem: {},
    ),
    operation: {
      try Core.Process.Testing.$mock.withValue(
        .init(
          run: { results.didRun = true },
          waitUntilExit: {
            results.didWaitUntilExit = true
          }), operation: {
          try executor.execute(script)
        })
    })

  #expect(script.count == 1)
  #expect(script[0].arguments == ["-la"])
  #expect(script[0].currentDirectoryURL == nil)
  #expect(script[0].executableURL == URL(filePath: "/bin/ls"))
  #expect(script[0].environment?["SHELL"] == "/bin/zsh")
  #expect(script[0].environment?["TERM"] == "xterm-256color")

  #expect(results.didRun == true)
  #expect(results.didWaitUntilExit == true)
  #expect(results.didCreateDirectory == false)
  #expect(results.didRemoveDirectory == false)
}

@Test func shellSourceRunsWithRealTemporaryFile() throws {
  let processes = try ShellScript.Builder(.production).build("printf 'hello from shell'")
  let output = try ShellScript.Executor(.production).execute(processes)
  #expect(output == "hello from shell")
}

private func executePerl(_ source: String) throws -> String? {
  let process = Core.Process(.production, launchStyle: .headless(source))
  process.executableURL = URL(fileURLWithPath: "/usr/bin/perl")
  process.arguments = ["-e", source]
  return try ShellScript.Executor(.production).execute(process)
}

@Test func shellDrainsLargeStderrAndPrefersEmptyStdout() throws {
  guard ProcessInfo.processInfo.environment["RUN_PIPE_DEADLOCK_REGRESSION"] == "1" else { return }
  #expect(try executePerl("print STDERR 'e' x 3000000") == "")
}

@Test func shellPreservesLargeStderrFallback() throws {
  guard ProcessInfo.processInfo.environment["RUN_PIPE_DEADLOCK_REGRESSION"] == "1" else { return }
  let output = try executePerl("print STDOUT chr(255); print STDERR 'e' x 1500000")
  #expect(output == String(repeating: "e", count: 1500000))
}

@Test func shellDoesNotWaitForDescendantPipeEOF() throws {
  guard ProcessInfo.processInfo.environment["RUN_PIPE_DEADLOCK_REGRESSION"] == "1" else { return }
  let start = DispatchTime.now().uptimeNanoseconds
  let output = try executePerl("if (fork() == 0) { sleep 3; exit 0 } print 'direct'")
  let elapsed = DispatchTime.now().uptimeNanoseconds - start
  #expect(output == "direct")
  #expect(elapsed < 2_500_000_000)
}

@Test func shellCapturesDirectChildBufferedOutput() throws {
  guard ProcessInfo.processInfo.environment["RUN_PIPE_DEADLOCK_REGRESSION"] == "1" else { return }
  let output = try executePerl("if (fork() == 0) { sleep 3; exit 0 } print 'x' x 1000000")
  #expect(output == String(repeating: "x", count: 1000000))
}

@Test func shellRejectsOversizedStderrAndReapsChild() throws {
  guard ProcessInfo.processInfo.environment["RUN_PIPE_DEADLOCK_REGRESSION"] == "1" else { return }
  let pidFile = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  defer { try? FileManager.default.removeItem(at: pidFile) }
  let source = "open(my $f, '>', $ARGV[0]) or die $!; print $f $$; close $f; print STDOUT 'valid'; while (1) { print STDERR 'e' x 65536 or die $! }"
  let process = Core.Process(.production, launchStyle: .headless(source))
  process.executableURL = URL(fileURLWithPath: "/usr/bin/perl")
  process.arguments = ["-e", source, pidFile.path]
  #expect(throws: Core.Process.CaptureError.standardErrorLimitExceeded(limit: 64 * 1024 * 1024)) {
    try ShellScript.Executor(.production).execute(process)
  }
  let pid = try #require(Int32(String(contentsOf: pidFile, encoding: .utf8)))
  #expect(kill(pid, 0) == -1 && errno == ESRCH)
}

@Test func shellCapturesStdoutAtLimit() throws {
  guard ProcessInfo.processInfo.environment["RUN_PIPE_DEADLOCK_REGRESSION"] == "1" else { return }
  let output = try executePerl("alarm 30; binmode STDOUT; print 'x' x (64 * 1024 * 1024) or die $!")
  let value = try #require(output)
  #expect(value.utf8.count == Core.Process.standardOutputCaptureLimit)
  #expect(value.utf8.allSatisfy { $0 == 120 })
}

@Test func shellRejectsOversizedStdoutAndReapsChild() throws {
  guard ProcessInfo.processInfo.environment["RUN_PIPE_DEADLOCK_REGRESSION"] == "1" else { return }
  let pidFile = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  defer { try? FileManager.default.removeItem(at: pidFile) }
  let source = "alarm 30; open(my $f, '>', $ARGV[0]) or die $!; print $f $$; close $f; binmode STDOUT; while (1) { print STDOUT 'x' x 65536 or die $! }"
  let process = Core.Process(.production, launchStyle: .headless(source))
  process.executableURL = URL(fileURLWithPath: "/usr/bin/perl")
  process.arguments = ["-e", source, pidFile.path]
  #expect(throws: Core.Process.CaptureError.standardOutputLimitExceeded(limit: 64 * 1024 * 1024)) {
    try ShellScript.Executor(.production).execute(process)
  }
  let pid = try #require(Int32(String(contentsOf: pidFile, encoding: .utf8)))
  #expect(kill(pid, 0) == -1 && errno == ESRCH)
}

@Test func shellCleansUpAndPreservesLaunchError() throws {
  let processes = try ShellScript.Builder(.testing).build("echo hello")
  let results = TestResults()
  Core.FileManager.Testing.$mock.withValue(.init(createFile: true, removeItem: {
    results.didRemoveDirectory = true
    throw ExecutorTestError.cleanup
  })) {
    Core.Process.Testing.$mock.withValue(.init(run: { throw ExecutorTestError.launch })) {
      #expect(throws: ExecutorTestError.launch) {
        try ShellScript.Executor(.testing).execute(processes)
      }
    }
  }
  #expect(results.didRemoveDirectory)
}

@Test func testExecutationShell() throws {
  let builder = ShellScript.Builder(.testing)
  let source = "ls -la"
  let script = try builder.build(source)
  let executor = ShellScript.Executor(.testing)
  let results = TestResults()
  let data = Data("A,B,C".utf8)
  var output: String?

  try Core.FileManager.Testing.$mock.withValue(
    .init(
      contentsAtPath: nil,
      createDirectoryAtUrl: {
        results.didCreateDirectory = true
        return URL(filePath: "/tmp/testExecutationShell with spaces")
      },
      createFile: true,
      removeItem: {
        results.didRemoveDirectory = true
      },
    ),
    operation: {
      try Core.Process.Testing.$mock.withValue(
        .init(
          run: { results.didRun = true },
          waitUntilExit: {
            results.didWaitUntilExit = true
          }), operation: {
          try Core.FileHandle.Testing.$mock.withValue(.init(readToEnd: data)) {
            output = try executor.execute(script)
          }
        })
    })

  #expect(output == "A,B,C")

  #expect(script.count == 1)
  #expect(script[0].arguments == ["-i", "-l", "/tmp/testExecutationShell with spaces/script"])
  #expect(script[0].currentDirectoryURL == nil)
  #expect(script[0].executableURL == URL(filePath: "/bin/zsh"))
  #expect(script[0].environment?["SHELL"] == "/bin/zsh")
  #expect(script[0].environment?["TERM"] == "xterm-256color")

  #expect(results.didRun == true)
  #expect(results.didWaitUntilExit == true)
  #expect(results.didCreateDirectory == true)
  #expect(results.didRemoveDirectory == true)
}

@Test func inlineShellInheritsWorkingDirectory() throws {
  let expected = URL(fileURLWithPath: Foundation.FileManager.default.currentDirectoryPath)
    .resolvingSymlinksInPath().path
  let processes = try ShellScript.Builder(.production).build("/bin/pwd -P")
  let output = try ShellScript.Executor(.production).execute(processes)
  #expect(output?.trimmingCharacters(in: .newlines) == expected)
}

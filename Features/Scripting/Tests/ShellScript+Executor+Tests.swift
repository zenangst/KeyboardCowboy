@testable import CowboyCore
import Foundation
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
  let source = "/bin/ls -la"
  let script = try builder.build(source)
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
        return URL(filePath: "/tmp/testExecutationShell")
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
  #expect(script[0].arguments == ["-i", "-l", "testExecutationShell/script"])
  #expect(script[0].currentDirectoryURL == URL(filePath: "/tmp"))
  #expect(script[0].executableURL == URL(filePath: "/bin/zsh"))
  #expect(script[0].environment?["SHELL"] == "/bin/zsh")
  #expect(script[0].environment?["TERM"] == "xterm-256color")

  #expect(results.didRun == true)
  #expect(results.didWaitUntilExit == true)
  #expect(results.didCreateDirectory == true)
  #expect(results.didRemoveDirectory == true)
}

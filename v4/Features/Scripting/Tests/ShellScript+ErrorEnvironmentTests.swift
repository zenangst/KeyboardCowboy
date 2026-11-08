@testable import FileSystem
@testable import ProcessSystem
@testable import CowboyCore
import Foundation
@testable import ScriptingFeature
import Testing

private enum ShellBoundaryError: Error {
  case directory, launch, cleanup
}

@Test func shellCreationFailureDoesNotLaunchAndPreservesOriginalError() throws {
  let processes = try ShellScript.Builder(.testing).build("echo hello")
  Core.FileManager.Testing.$mock.withValue(.init(createFile: false, removeItem: {
    throw ShellBoundaryError.cleanup
  })) {
    Core.Process.Testing.$mock.withValue(.init(run: { throw ShellBoundaryError.launch })) {
      #expect(throws: ShellScript.Executor.Error.createFileFailed) {
        try ShellScript.Executor(.testing).execute(processes)
      }
    }
  }
}

@Test func shellCleanupFailureAfterSuccessIsReported() throws {
  let processes = try ShellScript.Builder(.testing).build("echo hello")
  Core.FileManager.Testing.$mock.withValue(.init(createFile: true, removeItem: {
    throw ShellBoundaryError.cleanup
  })) {
    Core.Process.Testing.$mock.withValue(.init(run: {}, waitUntilExit: {})) {
      #expect(throws: ShellBoundaryError.cleanup) {
        try ShellScript.Executor(.testing).execute(processes)
      }
    }
  }
}

@Test func shellDirectoryCreationFailureIsReported() throws {
  let processes = try ShellScript.Builder(.testing).build("echo hello")
  Core.FileManager.Testing.$mock.withValue(.init(createDirectoryAtUrl: {
    throw ShellBoundaryError.directory
  }, createFile: true, removeItem: { throw ShellBoundaryError.cleanup })) {
    Core.Process.Testing.$mock.withValue(.init(run: { throw ShellBoundaryError.launch })) {
      #expect(throws: ShellBoundaryError.directory) {
        try ShellScript.Executor(.testing).execute(processes)
      }
    }
  }
}

@Test func shellBuildersApplyEnvironmentConsistently() throws {
  try Core.ProcessInfo.Testing.$mock.withValue([
    "PATH": "/custom/bin", "SHELL": "/bin/bash", "TERM": "original", "CUSTOM": "value",
  ]) {
    let builder = ShellScript.Builder(.testing)
    let processes = try builder.build("echo hello") + [
      builder.buildExecutable(at: URL(fileURLWithPath: "/bin/echo"), arguments: []),
      builder.buildFile(at: "/example/script"),
    ]
    for process in processes {
      #expect(process.environment?["PATH"] == "/usr/local/bin:/opt/homebrew/bin:/custom/bin")
      #expect(process.environment?["SHELL"] == "/bin/bash")
      #expect(process.environment?["TERM"] == "xterm-256color")
      #expect(process.environment?["CUSTOM"] == "value")
    }
    #expect(processes[0].executableURL == URL(fileURLWithPath: "/bin/bash"))
    #expect(processes[2].executableURL == URL(fileURLWithPath: "/bin/bash"))
  }
}

@Test(arguments: [false, true]) func shellBuilderDefaultsMissingOrEmptyPath(empty: Bool) throws {
  let environment = empty ? ["PATH": ""] : [:]
  try Core.ProcessInfo.Testing.$mock.withValue(environment) {
    let process = try #require(ShellScript.Builder(.testing).build("echo hello").first)
    #expect(process.environment?["PATH"] == "/usr/local/bin:/opt/homebrew/bin:")
    #expect(process.environment?["SHELL"] == "/bin/zsh")
    #expect(process.environment?["TERM"] == "xterm-256color")
    #expect(process.executableURL == URL(fileURLWithPath: "/bin/zsh"))
    #expect(process.arguments == ["-i", "-l"])
  }
}

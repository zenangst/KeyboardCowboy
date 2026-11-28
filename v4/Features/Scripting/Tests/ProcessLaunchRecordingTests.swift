import FileSystem
import Foundation
import ProcessSystem
@testable import ScriptingFeature
import Testing

#if DEBUG
private final class LaunchRecorder: @unchecked Sendable {
  private let lock = NSLock()
  private var storage: [ProcessSystem.Process.LaunchConfiguration] = []

  func record(_ configuration: ProcessSystem.Process.LaunchConfiguration) {
    lock.lock()
    defer { lock.unlock() }
    storage.append(configuration)
  }

  var launches: [ProcessSystem.Process.LaunchConfiguration] {
    lock.lock()
    defer { lock.unlock() }
    return storage
  }
}

@Test func recordsInlineShellConfigurationAtLaunch() throws {
  let recorder = LaunchRecorder()
  let processes = try ShellScript.Builder(.testing).build("echo hello")
  try FileSystem.FileManager.Testing.$mock.withValue(.init(
    createDirectoryAtUrl: { URL(filePath: "/tmp/launch path") },
    createFile: true,
  )) {
    try ProcessSystem.Process.Testing.$mock.withValue(.init(observeLaunch: { recorder.record($0) })) {
      _ = try ShellScript.Executor(.testing).execute(processes)
    }
  }
  let launch = try #require(recorder.launches.first)
  #expect(recorder.launches.count == 1)
  #expect(launch.executableURL == URL(filePath: "/bin/zsh"))
  #expect(launch.arguments == ["-i", "-l", "/tmp/launch path/script"])
  #expect(launch.currentDirectoryURL == nil)
  #expect(launch.environment?["TERM"] == "xterm-256color")
  #expect(launch.environment?["SHELL"] == "/bin/zsh")
}

@Test func failedInlineFileCreationDoesNotLaunch() throws {
  let recorder = LaunchRecorder()
  let processes = try ShellScript.Builder(.testing).build("echo hello")
  FileSystem.FileManager.Testing.$mock.withValue(.init(createFile: false)) {
    ProcessSystem.Process.Testing.$mock.withValue(.init(observeLaunch: { recorder.record($0) })) {
      #expect(throws: (any Error).self) {
        try ShellScript.Executor(.testing).execute(processes)
      }
    }
  }
  #expect(recorder.launches.isEmpty)
}
#endif

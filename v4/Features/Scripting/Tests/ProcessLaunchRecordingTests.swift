import CowboyCore
import Foundation
@testable import ScriptingFeature
import Testing

private final class LaunchRecorder: @unchecked Sendable {
  private let lock = NSLock()
  private var storage: [Core.Process.LaunchConfiguration] = []

  func record(_ configuration: Core.Process.LaunchConfiguration) {
    lock.lock()
    defer { lock.unlock() }
    storage.append(configuration)
  }

  var launches: [Core.Process.LaunchConfiguration] {
    lock.lock()
    defer { lock.unlock() }
    return storage
  }
}

@Test func recordsInlineShellConfigurationAtLaunch() throws {
  let recorder = LaunchRecorder()
  let processes = try ShellScript.Builder(.testing).build("echo hello")
  try Core.FileManager.Testing.$mock.withValue(.init(
    createDirectoryAtUrl: { URL(filePath: "/tmp/launch path") },
    createFile: true
  )) {
    try Core.Process.Testing.$mock.withValue(.init(observeLaunch: { recorder.record($0) })) {
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
  Core.FileManager.Testing.$mock.withValue(.init(createFile: false)) {
    Core.Process.Testing.$mock.withValue(.init(observeLaunch: { recorder.record($0) })) {
      #expect(throws: (any Error).self) {
        try ShellScript.Executor(.testing).execute(processes)
      }
    }
  }
  #expect(recorder.launches.isEmpty)
}

import Foundation
import ProcessSystem
import RuntimeEnvironment

func launchShortcuts(_ arguments: [String], environment: RuntimeEnvironment.Mode) async throws
  -> (stdout: Data?, stderr: Data?, status: Int32) {
  let launch: @Sendable () throws -> (Data?, Data?, Int32) = {
    let process = ProcessSystem.Process(environment, launchStyle: .headless("/usr/bin/shortcuts"))
    process.executableURL = URL(filePath: "/usr/bin/shortcuts")
    process.arguments = arguments
    process.standardOutput = ProcessSystem.Pipe(environment)
    process.standardError = ProcessSystem.Pipe(environment)
    let output = try process.runAndCaptureOutputUnbounded()
    return (output.stdout, output.stderr, process.terminationStatus)
  }
  #if DEBUG
  let mock = ProcessSystem.Process.Testing.mock
  return try await Task.detached {
    try ProcessSystem.Process.Testing.$mock.withValue(mock, operation: launch)
  }.value
  #else
  return try await Task.detached(operation: launch).value
  #endif
}

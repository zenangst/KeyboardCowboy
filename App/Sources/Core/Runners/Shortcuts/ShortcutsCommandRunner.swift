import Foundation
import Intents

final class ShortcutsCommandRunner: Sendable {
  enum ShortcutsCommandRunnerError: Error {
    case executionFailed(String)
  }

  func run(_ command: ShortcutCommand,
           environment _: [String: String],
           checkCancellation: Bool) async throws -> String? {
    if checkCancellation { try Task.checkCancellation() }

    let process = Process()
    process.executableURL = URL(filePath: "/usr/bin/shortcuts")
    // Pass shortcutIdentifier as a separate argument to prevent shell injection
    process.arguments = ["run", command.shortcutIdentifier]

    let outputPipe = Pipe()
    let errorPipe = Pipe()
    process.standardOutput = outputPipe
    process.standardError = errorPipe

    try process.run()

    let outputData = try outputPipe.fileHandleForReading.readToEnd()
    let errorData = try errorPipe.fileHandleForReading.readToEnd()

    process.waitUntilExit()

    if process.terminationStatus != 0 {
      let errorOutput = errorData.flatMap { String(data: $0, encoding: .utf8) } ?? ""
      throw ShortcutsCommandRunnerError.executionFailed(errorOutput)
    }

    return outputData.flatMap { String(data: $0, encoding: .utf8) }
  }
}

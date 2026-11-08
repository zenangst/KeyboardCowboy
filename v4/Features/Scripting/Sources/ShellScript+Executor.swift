import FileSystem
import ProcessSystem
import CowboyCore
import Foundation

/// A script subprocess that exited unsuccessfully. Output is captured as raw
/// bytes so diagnostics are preserved even when they are not UTF-8.
public struct ScriptProcessError: Swift.Error, Sendable, LocalizedError {
  public enum Reason: Sendable {
    case exit
    case signal
  }

  public let status: Int32
  public let reason: Reason
  public let stdout: Data
  public let stderr: Data

  public var errorDescription: String? {
    let termination = reason == .signal ? "terminated by signal \(status)" : "exited with status \(status)"
    let output = String(decoding: stdout, as: UTF8.self)
    let error = String(decoding: stderr, as: UTF8.self)
    return "Script process \(termination)." + (output.isEmpty ? "" : "\nstdout: \(output)")
      + (error.isEmpty ? "" : "\nstderr: \(error)")
  }
}

extension ShellScript {
  final class Executor {
    enum Error: Swift.Error {
      case createFileFailed
    }

    let env: Core.Environment

    init(_ env: Core.Environment) {
      self.env = env
    }

    func executeFile(at path: String) throws -> String? {
      try Task.checkCancellation()
      return try execute(ShellScript.Builder(env).buildFile(at: path))
    }

    func execute(_ processes: [Process]) throws -> String? {
      try Task.checkCancellation()
      var output: String = ""
      for process in processes {
        try Task.checkCancellation()
        if let pOutput = try execute(process) {
          output.append(pOutput)
        }
      }

      try Task.checkCancellation()
      return output
    }

    func execute(_ process: Process) throws -> String? {
      try Task.checkCancellation()
      let output: String?

      switch process.launchStyle {
      case .headless:
        output = try run(process)
      case .shell:
        let fileManager = FileManager(env)
        let directoryPath = (try fileManager.createTemporaryDirectory().path as NSString)
          .expandingTildeInPath
        let tempPath = (directoryPath as NSString).appendingPathComponent("script")

        let data = process.source.data(using: .utf8)
        process.arguments?.append(tempPath)

        do {
          try Task.checkCancellation()
          guard fileManager.createFile(atPath: tempPath, contents: data) else {
            throw Error.createFileFailed
          }

          output = try run(process)
        } catch {
          try? fileManager.removeItem(atPath: directoryPath)
          try Task.checkCancellation()
          throw error
        }

        try fileManager.removeItem(atPath: directoryPath)
      }

      return output
    }

    // MARK: Private methods

    private func run(_ process: Process) throws -> String? {
      let standardOutput = Pipe(env)
      let standardError = Pipe(env)
      process.standardOutput = standardOutput
      process.standardError = standardError

      let captured = try process.runAndCaptureOutput()

      try Task.checkCancellation()
      if process.terminationReason != .exit || process.terminationStatus != 0 {
        throw ScriptProcessError(
          status: process.terminationStatus,
          reason: process.terminationReason == .uncaughtSignal ? .signal : .exit,
          stdout: captured.stdout ?? Data(),
          stderr: captured.stderr ?? Data())
      }

      let output: String
      if let data = captured.stdout,
         let rawOutput = String(data: data, encoding: .utf8) {
        let ansiEscapePattern = "\u{001B}\\[[0-?]*[ -/]*[@-~]"
        let regex = try NSRegularExpression(pattern: ansiEscapePattern, options: [])
        let range = NSRange(rawOutput.startIndex..., in: rawOutput)
        let cleanOutput = regex.stringByReplacingMatches(in: rawOutput, options: [], range: range, withTemplate: "")
        output = cleanOutput
      } else if let errorOutput = captured.stderr {
        output = String(data: errorOutput, encoding: .utf8) ?? ""
      } else {
        output = ""
      }

      return output
    }
  }
}

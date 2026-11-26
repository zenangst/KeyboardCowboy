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

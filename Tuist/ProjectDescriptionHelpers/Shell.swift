import Foundation

public final class Shell: Sendable {
  private let path: String

  public init(path: String) {
    self.path = path
  }

  public func run(_ command: String) throws -> String {
    let standardOutput = Pipe()
    let standardError = Pipe()
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/zsh")
    process.currentDirectoryURL = URL(filePath: path)
    process.arguments = ["-c", command]
    process.standardOutput = standardOutput
    process.standardError = standardError

    try process.run()
    let output: String
    if let data = try standardOutput.fileHandleForReading.readToEnd() {
      output = String(data: data, encoding: .utf8)!
    } else if let data = try standardError.fileHandleForReading.readToEnd() {
      output = String(data: data, encoding: .utf8)!
    } else {
      output = ""
    }

    process.waitUntilExit()

    return output
  }
}

import AXEssibility
import Cocoa
import Foundation

final class ShellScriptPlugin: @unchecked Sendable {
  enum ShellScriptPluginError: Error {
    case noData
    case scriptError(String)
  }
  let fileManager: FileManager

  init(_ fileManager: FileManager = .default) {
    self.fileManager = fileManager
  }

  func executeScript(_ source: String, environment: [String: String], checkCancellation: Bool) async throws -> String? {
    let url = try createTmpDirectory()
    let data = source.data(using: .utf8)
    _ = fileManager.createFile(atPath: url.path, contents: data, attributes: nil)
    let output = try await executeScript(at: url.path, environment: environment,
                                         checkCancellation: checkCancellation)

    try fileManager.removeItem(atPath: url.path)

    return output
  }

  func executeScript(at path: String, environment: [String: String],
                     checkCancellation: Bool) async throws -> String? {
    let filePath = path.sanitizedPath
    let command = (filePath as NSString).lastPathComponent
    let url = URL(fileURLWithPath: (filePath as NSString).deletingLastPathComponent)

    var shell: String = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
    if let data = FileManager.default.contents(atPath: path),
       let contents = String(data: data, encoding: .utf8) {
      let lines = contents.split(separator: "\n")
      if lines.count > 1 {
        let firstLine = lines[0]

        let shebang = "#!"
        if firstLine.contains(shebang) {
          let resolvedShell = firstLine
            .split(separator: shebang)
          if resolvedShell.count == 1 {
            shell = String(resolvedShell[0])
          }
        }
      }
    }

    shell = shell.trimmingCharacters(in: .whitespacesAndNewlines)

    let (process, pipe, errorPipe) = createProcess(shell: shell)

    process.arguments = ["-i", "-l", command]
    process.environment = environment
    process.currentDirectoryURL = url

    if checkCancellation { try Task.checkCancellation() }

    try process.run()

    let output: String

    if let data = try pipe.fileHandleForReading.readToEnd(),
       let rawOutput = String(data: data, encoding: .utf8) {
      let ansiEscapePattern = "\u{001B}\\[[0-?]*[ -/]*[@-~]"
      let regex = try NSRegularExpression(pattern: ansiEscapePattern, options: [])
      let range = NSRange(rawOutput.startIndex..., in: rawOutput)
      let cleanOutput = regex.stringByReplacingMatches(in: rawOutput, options: [], range: range, withTemplate: "")
      output = cleanOutput
    } else if let errorPipe = try errorPipe.fileHandleForReading.readToEnd() {
      output = String(data: errorPipe, encoding: .utf8) ?? ""
      throw ShellScriptPluginError.scriptError(output)
    } else {
      output = ""
    }

    process.waitUntilExit()

    if process.terminationStatus != 0 {
      throw ShellScriptPluginError.scriptError(output)
    }

    return output
  }

  // MARK: Private methods

  private func createTmpDirectory() throws -> URL {
    let tmpName = UUID().uuidString
    let tmpDirectory = NSTemporaryDirectory()
    var url = URL(fileURLWithPath: tmpDirectory)
    url.appendPathComponent(Bundle.main.bundleIdentifier!)

    try fileManager.createDirectory(at: url, withIntermediateDirectories: true)

    url.appendPathComponent(tmpName)

    return url
  }

  private func createProcess(shell: String) -> (Process, Pipe, Pipe) {
    let outputPipe = Pipe()
    let errorPipe = Pipe()
    let process = Process()

    process.executableURL = URL(filePath: shell)
    process.standardOutput = outputPipe
    process.standardError = errorPipe

    return (process, outputPipe, errorPipe)
  }
}

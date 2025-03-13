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
    var shell: String
    let processArguments: [String]

    if let data = FileManager.default.contents(atPath: path),
       let contents = String(data: data, encoding: .utf8),
       let firstLine = contents.split(separator: "\n").first,
       firstLine.hasPrefix("#!") {

      let interpreterLine = firstLine.dropFirst(2).trimmingCharacters(in: .whitespacesAndNewlines)
      let tokens = interpreterLine.split(separator: " ").map(String.init)
      if let interpreter = tokens.first {
        shell = interpreter
        processArguments = Array(tokens.dropFirst()) + [command]
      } else {
        shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        processArguments = ["-i", "-l", command]
      }
    } else {
      shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
      processArguments = ["-i", "-l", command]
    }

    shell = shell.trimmingCharacters(in: .whitespacesAndNewlines)

    let (process, pipe, errorPipe) = createProcess(shell: shell)
    process.arguments = processArguments
    var environment = ProcessInfo.processInfo.environment
    environment["TERM"] = "xterm-256color"
    environment["PATH"] = "/usr/local/bin:/opt/homebrew/bin:" + (environment["PATH"] ?? "")
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

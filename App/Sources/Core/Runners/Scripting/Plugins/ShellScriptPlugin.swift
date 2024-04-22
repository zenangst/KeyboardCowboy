import AXEssibility
import Cocoa
import Foundation

final class ShellScriptPlugin: @unchecked Sendable {
  enum ShellScriptPluginError: Error {
    case noData
  }
  let fileManager: FileManager

  init(_ fileManager: FileManager = .default) {
    self.fileManager = fileManager
  }

  func executeScript(_ source: String, environment: [String: String], checkCancellation: Bool) throws -> String? {
    let url = try createTmpDirectory()
    let data = source.data(using: .utf8)
    _ = fileManager.createFile(atPath: url.path, contents: data, attributes: nil)
    let output = try executeScript(at: url.path, environment: environment,
                                   checkCancellation: checkCancellation)

    try fileManager.removeItem(atPath: url.path)

    return output
  }

  func executeScript(at path: String, environment: [String: String],
                     checkCancellation: Bool) throws -> String? {
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

    let (process, pipe, errorPipe) = createProcess(shell: shell)

    process.arguments = ["-i", "-l", command]
    process.environment = environment
    process.currentDirectoryURL = url

    if checkCancellation { try Task.checkCancellation() }

    try process.run()

    let output: String

    if let data = try pipe.fileHandleForReading.readToEnd() {
      output = String(data: data, encoding: .utf8) ?? ""
    } else if let errorPipe = try errorPipe.fileHandleForReading.readToEnd() {
      output = String(data: errorPipe, encoding: .utf8) ?? ""
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

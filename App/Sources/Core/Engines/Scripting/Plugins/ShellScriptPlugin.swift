import Foundation

final class ShellScriptPlugin {
  enum ShellScriptPluginError: Error {
    case noData
  }
  let fileManager: FileManager

  init(_ fileManager: FileManager = .default) {
    self.fileManager = fileManager
  }

  func executeScript(_ source: String) throws -> String? {
    let url = try createTmpDirectory()
    let data = source.data(using: .utf8)
    _ = fileManager.createFile(atPath: url.path, contents: data, attributes: nil)
    let output = try executeScript(at: url.path)

    try fileManager.removeItem(atPath: url.path)

    return output
  }

  func executeScript(at path: String) throws -> String? {
    let filePath = path.sanitizedPath
    let command = (filePath as NSString).lastPathComponent
    let url = URL(fileURLWithPath: (filePath as NSString).deletingLastPathComponent)
    let (process, pipe, _) = createProcess()

    process.arguments = ["-i", "-l", command]
    process.currentDirectoryURL = url

    try Task.checkCancellation()

    try process.run()

    let output: String
    if let data = try pipe.fileHandleForReading.readToEnd() {
      output = String(data: data, encoding: .utf8) ?? ""
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

  private func createProcess() -> (Process, Pipe, Pipe) {
    let outputPipe = Pipe()
    let errorPipe = Pipe()
    let process = Process()
    let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"

    process.executableURL = URL(filePath: shell)
    process.standardOutput = outputPipe
    process.standardError = errorPipe

    return (process, outputPipe, errorPipe)
  }
}

import AXEssibility
import Cocoa
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
    var environment: [String: String] = ProcessInfo.processInfo.environment
    environment["TERM"] = "xterm-256color"

    let filePath = path.sanitizedPath
    let command = (filePath as NSString).lastPathComponent
    let url = URL(fileURLWithPath: (filePath as NSString).deletingLastPathComponent)
    let (process, pipe, errorPipe) = createProcess()

    process.arguments = ["-i", "-l", command]

    if let frontmostApplication = NSWorkspace.shared.frontmostApplication {
      let app = AppAccessibilityElement(frontmostApplication.processIdentifier)
      if let focusedWindow = try? app.focusedWindow(),
         let documentPath = focusedWindow.document {
        let url = URL(filePath: documentPath)

        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
          environment["DIRECTORY"] = (components.path as NSString).deletingLastPathComponent
          environment["FILE"] = url.lastPathComponent
          environment["FILENAME"] = (url.lastPathComponent as NSString).deletingPathExtension
          environment["EXTENSION"] = (url.lastPathComponent as NSString).pathExtension
        }

      }
    }

    process.environment = environment
    process.currentDirectoryURL = url

    try Task.checkCancellation()

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

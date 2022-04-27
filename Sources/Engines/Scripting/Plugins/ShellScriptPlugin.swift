import Foundation

final class ShellScriptPlugin {
  func executeScript(_ source: String) {
    // TODO: Create tmp directory with a script.
  }

  func executeScript(at path: String) throws {
    let filePath = path.sanitizedPath
    let command = (filePath as NSString).lastPathComponent
    let url = URL(fileURLWithPath: (filePath as NSString).deletingLastPathComponent)
    let process = createProcess()

    process.arguments = ["-i", "-l", command]
    process.currentDirectoryURL = url

    try process.run()

    process.waitUntilExit()
  }

  // MARK: Private methods

  private func createProcess() -> Process {
    let outputPipe = Pipe()
    let errorPipe = Pipe()
    let process = Process()

    process.launchPath = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
    process.standardOutput = outputPipe
    process.standardError = errorPipe

    return process
  }
}

import CowboyCore
import Foundation

extension ShellScript {
  final class Executor {
    enum Error: Swift.Error {
      case createFileFailed
    }

    let env: Core.Environment

    init(_ env: Core.Environment) {
      self.env = env
    }

    func execute(_ processes: [Process]) throws -> String? {
      var output: String = ""
      for process in processes {
        if let pOutput = try execute(process) {
          output.append(pOutput)
        }
      }

      return output
    }

    func execute(_ process: Process) throws -> String? {
      let output: String?

      switch process.kind {
      case .headless:
        output = try run(process)
      case .shell:
        let fileManager = FileManager(env)
        let tempPath = (try fileManager.createTemporaryDirectory().path as NSString)
          .expandingTildeInPath

        let data = process.source.data(using: .utf8)
        let lastPathComponent = (tempPath as NSString).lastPathComponent
        let currentDirectoryURL = URL(fileURLWithPath: (tempPath as NSString).deletingLastPathComponent)

        process.arguments?.append(lastPathComponent)
        process.currentDirectoryURL = currentDirectoryURL

        guard fileManager.createFile(atPath: tempPath, contents: data) else {
          throw Error.createFileFailed
        }

        output = try run(process)

        try fileManager.removeItem(atPath: tempPath)
      }

      return output
    }

    // MARK: Private methods

    private func run(_ process: Process) throws -> String? {
      let standardOutput = Pipe(env)
      let standardError = Pipe(env)
      process.standardOutput = standardOutput
      process.standardError = standardError

      try process.run()

      let output: String
      if let data = try standardOutput.fileHandleForReading.readToEnd(),
         let rawOutput = String(data: data, encoding: .utf8) {
        let ansiEscapePattern = "\u{001B}\\[[0-?]*[ -/]*[@-~]"
        let regex = try NSRegularExpression(pattern: ansiEscapePattern, options: [])
        let range = NSRange(rawOutput.startIndex..., in: rawOutput)
        let cleanOutput = regex.stringByReplacingMatches(in: rawOutput, options: [], range: range, withTemplate: "")
        output = cleanOutput
      } else if let errorOutput = try standardError.fileHandleForReading.readToEnd() {
        output = String(data: errorOutput, encoding: .utf8) ?? ""
      } else {
        output = ""
      }

      process.waitUntilExit()

      return output
    }
  }
}

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

    func executeFile(at path: String) throws -> String? {
      try execute(ShellScript.Builder(env).buildFile(at: path))
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
          guard fileManager.createFile(atPath: tempPath, contents: data) else {
            throw Error.createFileFailed
          }

          output = try run(process)
        } catch {
          try? fileManager.removeItem(atPath: directoryPath)
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

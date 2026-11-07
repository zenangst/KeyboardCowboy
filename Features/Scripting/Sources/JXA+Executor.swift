import CowboyCore
import Foundation
import System

extension JXA {
  final class Executor {
    let env: Core.Environment
    let fileManager: FileManager

    init(_ env: Core.Environment) {
      self.env = env
      self.fileManager = FileManager(env)
    }

    func execute(_ filePath: FilePath) throws -> (String?, [Process]) {
      try Task.checkCancellation()
      let path = filePath.path

      guard fileManager.fileExists(atPath: path) else {
        throw JXA.Error.unableToFindFile(filePath)
      }

      return try runScript(at: path)
    }

    func execute(_ source: String) throws -> (String?, [Process]) {
      try Task.checkCancellation()
      let directory = try fileManager.createTemporaryDirectory()
      let tmpPath = directory.appendingPathComponent("script.js").path
      let data = source.data(using: .utf8)

      let result: (String?, [Process])
      do {
        try Task.checkCancellation()
        guard fileManager.createFile(atPath: tmpPath, contents: data) else {
          throw JXA.Error.createFileFailed
        }
        result = try runScript(at: tmpPath)
      } catch {
        try? fileManager.removeItem(atPath: directory.path)
        try Task.checkCancellation()
        throw error
      }

      try fileManager.removeItem(atPath: directory.path)

      return result
    }

    // MARK: Private methods

    private func runScript(at path: String) throws -> (String?, [Process]) {
      let process = ShellScript.Builder(env).buildExecutable(
        at: URL(fileURLWithPath: "/usr/bin/osascript"), arguments: ["-l", "JavaScript", path])
      let processes = [process]
      let output = try ShellScript.Executor(env).execute(processes)

      return (output, processes)
    }
  }
}

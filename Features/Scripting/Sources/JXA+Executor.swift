import CowboyCore
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
      let path = filePath.path

      guard fileManager.fileExists(atPath: path) else {
        throw JXA.Error.unableToFindFile(filePath)
      }

      return try runScript(at: path)
    }

    func execute(_ source: String) throws -> (String?, [Process]) {
      let directory = try fileManager.createTemporaryDirectory()
      let tmpPath = directory.appendingPathComponent("script.js").path
      let data = source.data(using: .utf8)

      let result: (String?, [Process])
      do {
        guard fileManager.createFile(atPath: tmpPath, contents: data) else {
          throw JXA.Error.createFileFailed
        }
        result = try runScript(at: tmpPath)
      } catch {
        try? fileManager.removeItem(atPath: directory.path)
        throw error
      }

      try fileManager.removeItem(atPath: directory.path)

      return result
    }

    // MARK: Private methods

    private func runScript(at path: String) throws -> (String?, [Process]) {
      let jxaSource = "/usr/bin/osascript -l JavaScript"
      let processes = try ShellScript.Builder(env).build(jxaSource)
      processes.first?.arguments?.append(path)
      let output = try ShellScript.Executor(env).execute(processes)

      return (output, processes)
    }
  }
}

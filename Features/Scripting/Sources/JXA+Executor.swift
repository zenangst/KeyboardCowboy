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
      let path = filePath.string

      guard fileManager.fileExists(atPath: path) else {
        throw JXA.Error.unableToFindFile(filePath)
      }

      return try runScript(at: path)
    }

    func execute(_ source: String) throws -> (String?, [Process]) {
      let tmpPath = try fileManager.createTemporaryDirectory().path
      let data = source.data(using: .utf8)

      fileManager.createFile(atPath: tmpPath, contents: data)

      let result = try runScript(at: tmpPath)

      try fileManager.removeItem(atPath: tmpPath)

      return result
    }

    // MARK: Private methods

    private func runScript(at path: String) throws -> (String?, [Process]) {
      let jxaSource = "/usr/bin/osascript -l JavaScript \(path)"
      let processes = try ShellScript.Builder(env).build(jxaSource)
      let output = try ShellScript.Executor(env).execute(processes)

      return (output, processes)
    }
  }
}

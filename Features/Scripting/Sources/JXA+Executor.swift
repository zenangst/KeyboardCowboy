import CowboyCore

extension JXA {
  final class Executor {
    let env: Core.Environment

    init(_ env: Core.Environment) {
      self.env = env
    }

    func execute(_ source: String) throws -> (String?, [Process]) {
      let fileManager = FileManager(env)
      let tmpPath = try fileManager.createTemporaryDirectory().path
      let data = source.data(using: .utf8)

      fileManager.createFile(atPath: tmpPath, contents: data)

      let jxaSource = "/usr/bin/osascript -l JavaScript \(tmpPath)"
      let process = try ShellScript.Builder(env).build(jxaSource)
      let output = try ShellScript.Executor(env).execute(process)

      return (output, process)
    }
  }
}

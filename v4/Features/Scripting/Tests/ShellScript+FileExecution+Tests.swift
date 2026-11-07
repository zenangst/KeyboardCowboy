@testable import CowboyCore
import Foundation
@testable import ScriptingFeature
import Testing

@Test(arguments: [true, false]) func shellFileUsesOriginalPathAndInterpreter(shebang: Bool) async throws {
  let path = "/tmp/Example Folder/script with spaces.sh"
  let contents = shebang ? "#!/bin/bash -e -u\necho hello" : "echo hello"
  try await confirmation("Original file is executed once") { ran in
    try Core.ProcessInfo.Testing.$mock.withValue(["SHELL": "/bin/zsh", "PATH": "/usr/bin"]) {
      try Core.FileManager.Testing.$mock.withValue(.init(
        contentsAtPath: Data(contents.utf8),
        createDirectoryAtUrl: { Issue.record("File execution must not create a temporary directory"); return URL(filePath: "/tmp") },
        removeItem: { Issue.record("File execution must not remove the original file") }
      )) {
        let process = ShellScript.Builder(.testing).buildFile(at: path)
        #expect(process.executableURL == URL(filePath: shebang ? "/bin/bash" : "/bin/zsh"))
        #expect(process.arguments == (shebang ? ["-e", "-u", "script with spaces.sh"] : ["-i", "-l", "script with spaces.sh"]))
        #expect(process.currentDirectoryURL == URL(filePath: "/tmp/Example Folder"))
        #expect(process.environment?["TERM"] == "xterm-256color")
        #expect(process.environment?["PATH"] == "/usr/local/bin:/opt/homebrew/bin:/usr/bin")
        try Core.Process.Testing.$mock.withValue(.init(run: { ran() }, waitUntilExit: {})) {
          _ = try ShellScript.Executor(.testing).executeFile(at: path)
        }
      }
    }
  }
}

@Test func shellFileBeginningWithDashIsNotAnInterpreterOption() {
  let process = ShellScript.Builder(.testing).buildFile(at: "/tmp/-script.sh")
  #expect(process.arguments?.last == "./-script.sh")
}

@Test func shellFileExecutesOriginalInItsOwnDirectory() throws {
  let directory = Foundation.FileManager.default.temporaryDirectory
    .appendingPathComponent("scripting file test \(UUID().uuidString)", isDirectory: true)
  try Foundation.FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
  defer { try? Foundation.FileManager.default.removeItem(at: directory) }
  let script = directory.appendingPathComponent("-script with spaces.sh")
  try "#!/bin/sh\nprintf '%s\\n%s' \"$PWD\" \"$0\"".write(to: script, atomically: true, encoding: .utf8)

  let output = try ShellScript.Executor(.production).executeFile(at: script.path)
  let lines = try #require(output).split(separator: "\n", omittingEmptySubsequences: false)
  #expect(lines.count == 2)
  let outputPath = try #require(lines.first).description
  #expect(lines.last == "./-script with spaces.sh")
  let actual = try Foundation.FileManager.default.attributesOfItem(atPath: outputPath)
  let expected = try Foundation.FileManager.default.attributesOfItem(atPath: directory.path)
  #expect(actual[.systemNumber] as? NSNumber == expected[.systemNumber] as? NSNumber)
  #expect(actual[.systemFileNumber] as? NSNumber == expected[.systemFileNumber] as? NSNumber)
  #expect(Foundation.FileManager.default.fileExists(atPath: script.path))
}

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

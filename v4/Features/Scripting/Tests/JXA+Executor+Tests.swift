@testable import CowboyCore
import Foundation
@testable import ScriptingFeature
import System
import Testing

@Test func testJXAExecutorHeadless() throws {
  let executor = JXA.Executor(.testing)
  let script = FilePath("/tmp/testscript")
  let data = Data("success".utf8)

  try Core.FileManager.Testing.$mock.withValue(.init(fileExistsAtPath: true), operation: {
    try Core.FileHandle.Testing.$mock.withValue(.init(readToEnd: data), operation: {
      let (output, processes) = try executor.execute(script)

      #expect(processes.count == 1)
      #expect(processes[0].arguments == ["-l", "JavaScript", "/tmp/testscript"])
      #expect(processes[0].currentDirectoryURL == nil)
      #expect(processes[0].executableURL == URL(filePath: "/usr/bin/osascript"))
      #expect(output == "success")
    })
  })
}

@Test func testJXAExecutorShell() throws {
  let executor = JXA.Executor(.testing)
  let script = "hello world!"
  let data = Data("success".utf8)

  try Core.FileManager.Testing.$mock.withValue(.init(createFile: true)) {
    try Core.FileHandle.Testing.$mock.withValue(.init(readToEnd: data), operation: {
      let (output, processes) = try executor.execute(script)

      #expect(processes.count == 1)
      #expect(processes[0].arguments == ["-l", "JavaScript", "/tmp/script.js"])
      #expect(processes[0].currentDirectoryURL == nil)
      #expect(processes[0].executableURL == URL(filePath: "/usr/bin/osascript"))
      #expect(output == "success")
    })
  }
}

@Test func jxaSourceRunsWithRealTemporaryFile() throws {
  let (output, _) = try JXA.Executor(.production).execute("'hello from JXA'")
  #expect(output?.trimmingCharacters(in: .whitespacesAndNewlines) == "hello from JXA")
}

@Test func jxaCleansUpWhenFileCreationFails() {
  let results = TestResults()
  Core.FileManager.Testing.$mock.withValue(.init(createFile: false, removeItem: {
    results.didRemoveDirectory = true
    throw ExecutorTestError.cleanup
  })) {
    #expect(throws: JXA.Error.self) {
      try JXA.Executor(.testing).execute("source")
    }
  }
  #expect(results.didRemoveDirectory)
}

@Test func jxaFilePathWithSpacesRemainsOneArgument() throws {
  try Core.FileManager.Testing.$mock.withValue(.init(fileExistsAtPath: true)) {
    let (_, processes) = try JXA.Executor(.testing).execute(FilePath("/tmp/a b; c.js"))
    #expect(processes[0].arguments == ["-l", "JavaScript", "/tmp/a b; c.js"])
  }
}

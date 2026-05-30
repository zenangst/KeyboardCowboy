import CowboyCore
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

  try Core.FileHandle.Testing.$mock.withValue(.init(readToEnd: data), operation: {
    let (output, processes) = try executor.execute(script)

    #expect(processes.count == 1)
    #expect(processes[0].arguments == ["-l", "JavaScript", "/tmp"])
    #expect(processes[0].currentDirectoryURL == nil)
    #expect(processes[0].executableURL == URL(filePath: "/usr/bin/osascript"))
    #expect(output == "success")
  })
}

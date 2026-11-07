@testable import CowboyCore
@testable import ScriptingFeature
import Foundation
import System
import Testing

@Test(arguments: [false, true]) func cachedAppleScriptExecutionReportsRuntimeError(file: Bool) throws {
  let executor = AppleScript.Executor(.testing)
  try Core.NSAppleScript.Testing.$mock.withValue(.init(compileAndReturnError: true)) {
    if file {
      _ = try executor.execute(FilePath("/tmp/applescript"), key: "cached")
    } else {
      _ = try executor.execute("return 1", key: "cached")
    }
  }

  try Core.NSAppleScript.Testing.$mock.withValue(.init(execute: {
    NSError(domain: "test", code: -1708, userInfo: [NSLocalizedDescriptionKey: "execution failed"])
  })) {
    do {
      if file {
        _ = try executor.execute(FilePath("/tmp/applescript"), key: "cached")
      } else {
        _ = try executor.execute("return 1", key: "cached")
      }
      Issue.record("Cached execution must report the runtime error")
    } catch Core.NSAppleScript.Error.unableToExecute(let error) {
      #expect((error as NSError).code == -1708)
      #expect((error as NSError).localizedDescription == "execution failed")
    } catch {
      Issue.record("Unexpected error: \(error)")
    }
  }
}

@Test func testAppleScriptExecutorUsingFilePath() throws {
  let executor = AppleScript.Executor(.testing)

  try Core.NSAppleScript.Testing.$mock.withValue(.init(compileAndReturnError: true), operation: {
    try Core.NSAppleEventDescriptor.Testing.$mock.withValue(.init(stringValue: "hello, world!"), operation: {
      #expect(executor.cache.get(for: "cacheKey") == nil)
      let (firstRun, firstOutput) = try executor.execute(FilePath("/tmp/applescript"), key: "cacheKey")
      #expect(firstOutput == "hello, world!")
      #expect(executor.cache.get(for: "cacheKey") === firstRun)

      let (secondRun, secondOutput) = try executor.execute(FilePath("/tmp/applescript"), key: "cacheKey")
      #expect(firstRun === secondRun)
      #expect(firstOutput == secondOutput)

      executor.cache.clear()

      let (thirdRun, thirdOutput) = try executor.execute("my script", key: "cacheKey")
      #expect(firstRun !== thirdRun)
      #expect(firstOutput == thirdOutput)
    })
  })
}

@Test func testAppleScriptExecutorUsingSource() throws {
  let executor = AppleScript.Executor(.testing)

  try Core.NSAppleScript.Testing.$mock.withValue(.init(compileAndReturnError: true), operation: {
    try Core.NSAppleEventDescriptor.Testing.$mock.withValue(.init(stringValue: "hello, world!"), operation: {
      #expect(executor.cache.get(for: "cacheKey") == nil)
      let (firstRun, firstOutput) = try executor.execute("my script", key: "cacheKey")
      #expect(firstOutput == "hello, world!")
      #expect(executor.cache.get(for: "cacheKey") === firstRun)

      let (secondRun, secondOutput) = try executor.execute("my script", key: "cacheKey")
      #expect(firstRun === secondRun)
      #expect(firstOutput == secondOutput)

      executor.cache.clear()

      let (thirdRun, thirdOutput) = try executor.execute("my script", key: "cacheKey")
      #expect(firstRun !== thirdRun)
      #expect(firstOutput == thirdOutput)
    })
  })
}

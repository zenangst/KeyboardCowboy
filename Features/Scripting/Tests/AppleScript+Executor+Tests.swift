@testable import CowboyCore
@testable import ScriptingFeature
import System
import Testing

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

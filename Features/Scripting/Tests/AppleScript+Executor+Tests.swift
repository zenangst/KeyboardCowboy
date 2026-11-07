@testable import CowboyCore
@testable import ScriptingFeature
import Foundation
import System
import Testing

@Test(arguments: [false, true]) @MainActor func cachedAppleScriptExecutionReportsRuntimeError(file: Bool) async throws {
  let executor = AppleScript.Executor(.testing)
  try Core.NSAppleScript.Testing.$mock.withValue(.init(compileAndReturnError: true)) {
    if file {
      _ = try executor.execute(FilePath("/tmp/applescript"), key: "cached")
    } else {
      _ = try executor.execute("return 1", key: "cached")
    }
  }

  Core.NSAppleScript.Testing.$mock.withValue(.init(execute: {
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

@Test(arguments: [false, true]) @MainActor func appleScriptCacheUsesOnlyTheKeyAndCanBeCleared(file: Bool) async throws {
  let executor = AppleScript.Executor(.testing)
  try Core.NSAppleEventDescriptor.Testing.$mock.withValue(.init(stringValue: "hello, world!")) {
    try Core.NSAppleScript.Testing.$mock.withValue(.init(compileAndReturnError: true)) {
      let output: String?
      if file {
        output = try executor.execute(FilePath("/tmp/applescript"), key: "shared")
      } else {
        output = try executor.execute("first source", key: "shared")
      }
      #expect(output == "hello, world!")
    }

    // Compilation now fails, so successful execution proves the cached script was reused.
    try Core.NSAppleScript.Testing.$mock.withValue(.init(compileAndReturnError: false)) {
      let output: String?
      if file {
        output = try executor.execute("different source", key: "shared")
      } else {
        output = try executor.execute(FilePath("/tmp/another-script"), key: "shared")
      }
      #expect(output == "hello, world!")
      do {
        _ = try executor.execute("first source", key: "different")
        Issue.record("A different key must compile a new script")
      } catch Core.NSAppleScript.Error.unableToCompile {}

      executor.clearCache()
      do {
        _ = try executor.execute("first source", key: "shared")
        Issue.record("Clearing the cache must require compilation")
      } catch Core.NSAppleScript.Error.unableToCompile {}
    }

    try Core.NSAppleScript.Testing.$mock.withValue(.init(compileAndReturnError: true)) {
      let output = try executor.execute("first source", key: "shared")
      #expect(output == "hello, world!")
    }
  }
}

@Test @MainActor func concurrentAppleScriptExecutionsShareCache() async throws {
  let executor = AppleScript.Executor(.testing)
  try await Core.NSAppleScript.Testing.$mock.withValue(.init(compileAndReturnError: true)) {
    try await withThrowingTaskGroup(of: Void.self) { group in
      for _ in 0..<20 {
        group.addTask {
          _ = try await executor.execute("source", key: "shared")
        }
      }
      try await group.waitForAll()
    }
  }
  // A fresh compile would fail; every concurrent request must leave a usable cached entry.
  try Core.NSAppleScript.Testing.$mock.withValue(.init(compileAndReturnError: false)) {
    _ = try executor.execute("different source", key: "shared")
  }
}

@Test @MainActor func reentrantAppleScriptExecutionIsRejectedAndCacheClearIsDeferred() throws {
  let executor = AppleScript.Executor(.testing)
  try Core.NSAppleScript.Testing.$mock.withValue(.init(compileAndReturnError: true, execute: {
    MainActor.assumeIsolated {
      #expect(throws: AppleScript.Executor.ExecutionError.reentrantExecution) {
        try executor.execute("nested", key: "nested")
      }
      executor.clearCache()
    }
    return nil
  })) {
    _ = try executor.execute("source", key: "shared")
  }
  Core.NSAppleScript.Testing.$mock.withValue(.init(compileAndReturnError: false)) {
    #expect(throws: Core.NSAppleScript.Error.self) {
      try executor.execute("source", key: "shared")
    }
  }
}

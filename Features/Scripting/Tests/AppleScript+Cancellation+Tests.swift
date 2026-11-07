@testable import CowboyCore
import Foundation
@testable import ScriptingFeature
import System
import Testing

@Test(arguments: [false, true]) @MainActor
func appleScriptCancelledBeforeExecutionDoesNotRun(file: Bool) async throws {
  let executor = AppleScript.Executor(.testing)
  let result = await Task { @MainActor in
    Core.NSAppleScript.Testing.$mock.withValue(.init(compileAndReturnError: true, execute: {
      Issue.record("A cancelled task must not run a script")
      return nil
    })) {
      withUnsafeCurrentTask { $0?.cancel() }
      do {
        if file { _ = try executor.execute(FilePath("/tmp/test.scpt"), key: "key") }
        else { _ = try executor.execute("source", key: "key") }
        return false
      } catch is CancellationError { return true }
      catch { Issue.record("Unexpected error: \(error)"); return false }
    }
  }.value
  #expect(result)
}

@Test(arguments: [false, true]) @MainActor
func appleScriptCancelledDuringExecutionDoesNotCacheResult(file: Bool) async throws {
  let executor = AppleScript.Executor(.testing)
  let result = await Task { @MainActor in
    Core.NSAppleScript.Testing.$mock.withValue(.init(compileAndReturnError: true, execute: {
      withUnsafeCurrentTask { $0?.cancel() }
      return nil
    })) {
      do {
        if file { _ = try executor.execute(FilePath("/tmp/test.scpt"), key: "key") }
        else { _ = try executor.execute("source", key: "key") }
        return false
      } catch is CancellationError { return true }
      catch { Issue.record("Unexpected error: \(error)"); return false }
    }
  }.value
  #expect(result)
  Core.NSAppleScript.Testing.$mock.withValue(.init(compileAndReturnError: false)) {
    #expect(throws: Core.NSAppleScript.Error.self) {
      try executor.execute("source", key: "key")
    }
  }
}

@Test(arguments: [false, true]) @MainActor
func cachedAppleScriptCancellationTakesPrecedenceOverRuntimeError(file: Bool) async throws {
  let executor = AppleScript.Executor(.testing)
  try Core.NSAppleScript.Testing.$mock.withValue(.init(compileAndReturnError: true)) {
    _ = try executor.execute("source", key: "key")
  }
  let result = await Task { @MainActor in
    Core.NSAppleScript.Testing.$mock.withValue(.init(execute: {
      withUnsafeCurrentTask { $0?.cancel() }
      return NSError(domain: "test", code: -1)
    })) {
      do {
        if file { _ = try executor.execute(FilePath("/tmp/test.scpt"), key: "key") }
        else { _ = try executor.execute("source", key: "key") }
        return false
      } catch is CancellationError { return true }
      catch { Issue.record("Unexpected error: \(error)"); return false }
    }
  }.value
  #expect(result)
}

@Test(arguments: [false, true]) @MainActor
func appleScriptCancellationTakesPrecedenceOverCompileError(file: Bool) async {
  let executor = AppleScript.Executor(.testing)
  let result = await Task { @MainActor in
    Core.NSAppleScript.Testing.$mock.withValue(.init(
      compileAndReturnError: false,
      execute: { Issue.record("Compilation failure must prevent execution"); return nil },
      compileError: {
        withUnsafeCurrentTask { $0?.cancel() }
        return NSError(domain: "test", code: -1)
      }
    )) {
      do {
        if file { _ = try executor.execute(FilePath("/tmp/test.scpt"), key: "key") }
        else { _ = try executor.execute("source", key: "key") }
        return false
      } catch is CancellationError { return true }
      catch { Issue.record("Unexpected error: \(error)"); return false }
    }
  }.value
  #expect(result)
}

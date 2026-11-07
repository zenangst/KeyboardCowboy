import CowboyCore
import Foundation
import ScriptingFeature
import System
import Testing

@MainActor private final class AppleScriptTrace {
  var events: [String] = []
}

@Test @MainActor func appleScriptMockRecordsKeyOnlyCacheBoundaries() throws {
  let trace = AppleScriptTrace()
  let executor = AppleScript.Executor(.testing)
  let mock = Core.NSAppleScript.Mock(
    compileAndReturnError: true,
    execute: {
      MainActor.assumeIsolated { trace.events.append("execute") }
      return nil
    },
    createSource: { source in
      MainActor.assumeIsolated { trace.events.append("source: \(source)") }
      return true
    },
    createFile: { url in
      MainActor.assumeIsolated { trace.events.append("file: \(url.path)") }
      return true
    },
    onCompile: { MainActor.assumeIsolated { trace.events.append("compile") } },
  )
  try Core.NSAppleScript.Testing.$mock.withValue(mock) {
    _ = try executor.execute("first", key: "shared")
    _ = try executor.execute(FilePath("/different.scpt"), key: "shared")
    _ = try executor.execute(FilePath("/file.scpt"), key: "file")
    _ = try executor.execute("changed", key: "file")
    executor.clearCache()
    _ = try executor.execute("after clear", key: "shared")
  }
  #expect(trace.events == [
    "source: first", "compile", "execute", "execute",
    "file: /file.scpt", "compile", "execute", "execute",
    "source: after clear", "compile", "execute",
  ])
}

@Test @MainActor func appleScriptMockConstructorFailuresAreNotCached() throws {
  let executor = AppleScript.Executor(.testing)
  let mock = Core.NSAppleScript.Mock(createSource: { _ in false }, createFile: { _ in false })
  try Core.NSAppleScript.Testing.$mock.withValue(mock) {
    do {
      _ = try executor.execute("bad source", key: "source")
      Issue.record("Expected source creation to fail")
    } catch Core.NSAppleScript.Error.unableToCreateAppleScript(let source) {
      #expect(source == "bad source")
    }
    do {
      _ = try executor.execute(FilePath("/bad.scpt"), key: "file")
      Issue.record("Expected file creation to fail")
    } catch Core.NSAppleScript.Error.unableToResolveAppleScript(let path) {
      #expect(path == URL(filePath: "/bad.scpt").absoluteString)
    }
  }
  try Core.NSAppleScript.Testing.$mock.withValue(.init(compileAndReturnError: true)) {
    _ = try executor.execute("good source", key: "source")
    _ = try executor.execute(FilePath("/good.scpt"), key: "file")
  }
}

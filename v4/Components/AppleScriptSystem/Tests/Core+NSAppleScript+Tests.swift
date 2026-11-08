import Cocoa
@testable import AppleScriptSystem
@testable import CowboyCore
import Testing

@Test(arguments: [false, true]) func compilationFailurePreservesDetails(provideErrorPointer: Bool) throws {
  try Core.NSAppleScript.Testing.$mock.withValue(.init(compileError: {
    NSError(domain: "test", code: -2741, userInfo: [
      NSLocalizedDescriptionKey: "Syntax error",
      NSLocalizedFailureReasonErrorKey: "Expected end of line",
    ])
  })) {
    let script = try Core.NSAppleScript(.testing, source: "invalid")
    var dictionary: NSDictionary?
    do {
      if provideErrorPointer {
        try script.compileAndReturnError(&dictionary)
      } else {
        try script.compileAndReturnError(nil)
      }
      Issue.record("Expected compilation to fail")
    } catch Core.NSAppleScript.Error.unableToCompileWithError(let error) {
      let error = error as NSError
      #expect(error.code == -2741)
      #expect(error.localizedDescription == "Syntax error")
      #expect(error.localizedFailureReason == "Expected end of line")
      if provideErrorPointer {
        #expect(dictionary?[Cocoa.NSAppleScript.errorNumber] as? Int == -2741)
      }
    } catch {
      Issue.record("Unexpected error: \(error)")
    }
  }
}

@Test func compilationFailureWithoutDetailsRetainsExistingError() throws {
  try Core.NSAppleScript.Testing.$mock.withValue(.init()) {
    let script = try Core.NSAppleScript(.testing, source: "invalid")
    do {
      try script.compileAndReturnError(nil)
      Issue.record("Expected compilation to fail")
    } catch Core.NSAppleScript.Error.unableToCompile {
      // The existing error remains the fallback when Cocoa supplies no details.
    } catch {
      Issue.record("Unexpected error: \(error)")
    }
  }
}

@Test(arguments: [false, true]) func executionFailurePreservesDetailsWithoutRequiringPointer(provideErrorPointer: Bool) throws {
  try Core.NSAppleScript.Testing.$mock.withValue(.init(execute: {
    NSError(domain: "test", code: -1708, userInfo: [NSLocalizedDescriptionKey: "Execution failed"])
  })) {
    let script = try Core.NSAppleScript(.testing, source: "source")
    var dictionary: NSDictionary?
    do {
      if provideErrorPointer { _ = try script.executeAndReturnError(&dictionary) }
      else { _ = try script.executeAndReturnError(nil) }
      Issue.record("Expected execution to fail")
    } catch Core.NSAppleScript.Error.unableToExecute(let error) {
      #expect((error as NSError).code == -1708)
      #expect((error as NSError).localizedDescription == "Execution failed")
      if provideErrorPointer { #expect(dictionary?[Cocoa.NSAppleScript.errorNumber] as? Int == -1708) }
    }
  }
}

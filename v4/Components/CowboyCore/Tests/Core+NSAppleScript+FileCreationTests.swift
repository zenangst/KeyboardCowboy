import Cocoa
@testable import CowboyCore
import Testing

@Test(arguments: [false, true]) func fileCreationFailurePreservesDetails(provideErrorPointer: Bool) {
  let url = URL(fileURLWithPath: "/missing/test.scpt")
  Core.NSAppleScript.Testing.$mock.withValue(.init(createFile: { _ in false }, createFileError: { _ in
    NSError(domain: "test", code: -43, userInfo: [
      NSLocalizedDescriptionKey: "File unavailable",
      NSLocalizedFailureReasonErrorKey: "File not found",
    ])
  })) {
    var dictionary: NSDictionary?
    do {
      if provideErrorPointer {
        _ = try Core.NSAppleScript(.testing, contentsOf: url, error: &dictionary)
      } else {
        _ = try Core.NSAppleScript(.testing, contentsOf: url, error: nil)
      }
      Issue.record("Expected file creation to fail")
    } catch Core.NSAppleScript.Error.unableToResolveAppleScriptWithError(let path, let error) {
      #expect(path == url.absoluteString)
      #expect(error.code == -43)
      #expect(error.localizedDescription == "File unavailable")
      #expect(error.localizedFailureReason == "File not found")
      if provideErrorPointer {
        #expect(dictionary?[Cocoa.NSAppleScript.errorNumber] as? Int == -43)
        #expect(dictionary?[Cocoa.NSAppleScript.errorBriefMessage] as? String == "File unavailable")
      }
    } catch {
      Issue.record("Unexpected error: \(error)")
    }
  }
}

@Test func fileCreationFailureWithoutDetailsRetainsFallback() {
  let url = URL(fileURLWithPath: "/missing/test.scpt")
  Core.NSAppleScript.Testing.$mock.withValue(.init(createFile: { _ in false })) {
    var dictionary: NSDictionary? = ["stale": true]
    do {
      _ = try Core.NSAppleScript(.testing, contentsOf: url, error: &dictionary)
      Issue.record("Expected file creation to fail")
    } catch Core.NSAppleScript.Error.unableToResolveAppleScript(let path) {
      #expect(path == url.absoluteString)
      #expect(dictionary == nil)
    } catch {
      Issue.record("Unexpected error: \(error)")
    }
  }
}

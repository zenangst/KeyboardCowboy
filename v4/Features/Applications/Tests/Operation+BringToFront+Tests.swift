#if DEBUG
@testable import AppleScriptRuntime
@testable import ApplicationsFeature
import Foundation
import Testing

@Test func bringToFrontCancellationTakesPrecedenceOverScriptError() async {
  let cancelled = await withTaskGroup(of: Bool.self, returning: Bool.self) { group in
    group.addTask {
      AppleScriptRuntime.NSAppleScript.Testing.$mock.withValue(.init(execute: {
        withUnsafeCurrentTask { $0?.cancel() }
        return NSError(domain: "test", code: 42)
      })) {
        do {
          try Operation.BringToFront(.testing)()
          return false
        } catch is CancellationError {
          return true
        } catch {
          return false
        }
      }
    }
    return await group.next() ?? false
  }
  #expect(cancelled)
}
#endif

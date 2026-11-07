import Foundation
import OpenFeature
import Testing

private actor TabScriptRecorder {
  var calls: [(String, String, Bool)] = []
  func record(_ name: String, _ source: String, _ cancellation: Bool) { calls.append((name, source, cancellation)) }
}

@Test(arguments: [String?.none, "0", "other", "-1 "])
func tabSearchAcceptsNonFailureResults(_ result: String?) async throws {
  let search = Open.BrowserTabSearch { _, _, _ in result }
  try await search.search("https://example.com", applicationName: "Safari", checkCancellation: false)
}

@Test func tabSearchBuildsEscapedScriptAndForwardsArguments() async throws {
  let recorder = TabScriptRecorder()
  let search = Open.BrowserTabSearch { name, source, cancellation in
    await recorder.record(name, source, cancellation)
    return "0"
  }
  try await search.search("https://example.com/\"a\\b", applicationName: "Browser \"A\\B", checkCancellation: true)
  let calls = await recorder.calls
  #expect(calls.count == 1)
  #expect(UUID(uuidString: calls[0].0) != nil)
  #expect(calls[0].1.contains("property matchingURL : \"https://example.com/\\\"a\\\\b\""))
  #expect(calls[0].1.contains("tell application \"Browser \\\"A\\\\B\""))
  #expect(calls[0].1.contains("if item y of tmp contains matchingURL then"))
  #expect(calls[0].2)
}

@Test func tabSearchSignalsNoMatchAndPropagatesScriptErrors() async {
  enum Failure: Error { case script }
  let noMatch = Open.BrowserTabSearch { _, _, _ in "-1" }
  await #expect(throws: Open.BrowserTabSearch.SearchError.couldNotFindOpenURL) {
    try await noMatch.search("url", applicationName: "Safari", checkCancellation: false)
  }
  let failing = Open.BrowserTabSearch { _, _, _ in throw Failure.script }
  await #expect(throws: Failure.self) {
    try await failing.search("url", applicationName: "Safari", checkCancellation: false)
  }
}

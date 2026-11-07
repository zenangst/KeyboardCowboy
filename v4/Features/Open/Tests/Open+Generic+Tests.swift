import Foundation
@testable import OpenFeature
import Testing

#if DEBUG
  private actor OpenRecorder {
    var calls: [(URL, URL?)] = []
    func record(_ url: URL, _ application: URL?) { calls.append((url, application)) }
  }

  @Test func genericOpenUsesParsedURLAndExplicitApplicationPath() async throws {
    let recorder = OpenRecorder()
    let mock = Open.System.Mock(open: { await recorder.record($0, $1) })
    let generic = Open.Generic(environment: .testing)
    let application = Open.TargetApplication(bundleIdentifier: "id", bundleName: "name", displayName: "display", path: "/Applications/Test.app")
    try await Open.System.Testing.$mock.withValue(mock) {
      try await generic.open("file:///tmp/a%20file", application: application)
      try await generic.open("https://example.com")
    }
    let calls = await recorder.calls
    #expect(calls.count == 2)
    #expect(calls[0].0 == URL(fileURLWithPath: "file:///tmp/a%20file"))
    #expect(calls[0].1 == URL(fileURLWithPath: application.path))
    #expect(calls[1].0 == URL(string: "https://example.com"))
    #expect(calls[1].1 == nil)
  }

  @Test func genericPropagatesSystemErrorsAndMetadata() async throws {
    enum Failure: Error { case expected }
    let mock = Open.System.Mock(open: { _, _ in throw Failure.expected }, isDirectory: { path in
      if path == "error" { throw Failure.expected }
      return path == "directory"
    })
    let generic = Open.Generic(environment: .testing)
    try await Open.System.Testing.$mock.withValue(mock) {
      await #expect(throws: Failure.self) { try await generic.open("/file") }
      let directory = try generic.isDirectory("directory")
      let file = try generic.isDirectory("file")
      #expect(directory)
      #expect(!file)
      #expect(throws: Failure.self) { try generic.isDirectory("error") }
    }
  }
#endif

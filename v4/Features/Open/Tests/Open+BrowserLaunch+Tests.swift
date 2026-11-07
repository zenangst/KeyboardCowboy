import Foundation
@testable import OpenFeature
import Testing

#if DEBUG
  private final class LaunchRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String] = []
    func record(_ value: String) { lock.lock(); defer { lock.unlock() }; storage.append(value) }
    var calls: [String] { lock.lock(); defer { lock.unlock() }; return storage }
  }

  @Test func browserLaunchUsesDistinctWorkspacePaths() async throws {
    let recorder = LaunchRecorder()
    let mock = Open.System.Mock(
      open: { url, app in recorder.record("explicit:\(url.absoluteString):\(app?.path ?? "nil")") },
      openDefault: { url in recorder.record("default:\(url.absoluteString)"); return false }
    )
    let launch = Open.BrowserLaunch(environment: .testing)
    let application = Open.TargetApplication(bundleIdentifier: "id", bundleName: "name", displayName: "display", path: "/Applications/Test.app")
    try await Open.System.Testing.$mock.withValue(mock) {
      try await launch.open("https://example.com", application: application)
      try await launch.open("https://example.com")
      try await launch.open("http://[")
    }
    #expect(recorder.calls == ["explicit:https://example.com:/Applications/Test.app", "default:https://example.com"])
  }

  @Test func browserLaunchPropagatesExplicitOpenErrors() async {
    enum Failure: Error { case open }
    let mock = Open.System.Mock(open: { _, _ in throw Failure.open })
    let launch = Open.BrowserLaunch(environment: .testing)
    let application = Open.TargetApplication(bundleIdentifier: "id", bundleName: "name", displayName: "display", path: "/app")
    await Open.System.Testing.$mock.withValue(mock) {
      await #expect(throws: Failure.self) { try await launch.open("https://example.com", application: application) }
    }
  }
#endif

import Foundation
@testable import OpenFeature
import Testing

#if DEBUG
  private final class BrowserRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String] = []
    func add(_ value: String) { lock.lock(); defer { lock.unlock() }; storage.append(value) }
    var calls: [String] { lock.lock(); defer { lock.unlock() }; return storage }
  }

  @Test func browserRaisesBeforeActivatingAndDefaultsToSafari() async throws {
    let recorder = BrowserRecorder()
    let mock = Open.System.Mock(
      firstRunningProcess: { recorder.add("lookup:\($0)"); return 42 },
      activate: { recorder.add("activate:\($0)"); return false }
    )
    let browser = Open.Browser(environment: .testing, tabSearch: Open.BrowserTabSearch { _, _, _ in
      recorder.add("script"); return nil
    }, raiseMatchingWindow: { pid, path in
      recorder.add("raise:\(pid):\(path)"); return true
    })
    try await Open.System.Testing.$mock.withValue(mock) {
      try await browser.open("https://example.com", checkCancellation: true)
    }
    #expect(recorder.calls == ["lookup:com.apple.Safari", "raise:42:https://example.com", "activate:42"])
  }

  @Test func browserUsesTabSearchOnlyAfterAXNoMatch() async throws {
    let recorder = BrowserRecorder()
    let mock = Open.System.Mock(firstRunningProcess: { recorder.add("lookup:\($0)"); return 123 })
    let browser = Open.Browser(environment: .testing, tabSearch: Open.BrowserTabSearch { _, source, cancellation in
      recorder.add("script:\(source.contains("tell application \"Display\"")):\(cancellation)")
      return "-1"
    }, raiseMatchingWindow: { _, _ in recorder.add("ax"); return false })
    let app = Open.TargetApplication(bundleIdentifier: "browser.id", bundleName: "Name", displayName: "Display", path: "/Browser.app")
    await Open.System.Testing.$mock.withValue(mock) {
      await #expect(throws: Open.BrowserTabSearch.SearchError.couldNotFindOpenURL) {
        try await browser.open("https://example.com", application: app, checkCancellation: true)
      }
    }
    #expect(recorder.calls == ["lookup:browser.id", "ax", "script:true:true"])
  }

  @Test func browserAXErrorsPropagateWithoutTabSearch() async {
    enum Failure: Error { case ax }
    let recorder = BrowserRecorder()
    let mock = Open.System.Mock(firstRunningProcess: { _ in 42 })
    let browser = Open.Browser(environment: .testing, tabSearch: Open.BrowserTabSearch { _, _, _ in
      recorder.add("script"); return nil
    }, raiseMatchingWindow: { _, _ in throw Failure.ax })
    await Open.System.Testing.$mock.withValue(mock) {
      await #expect(throws: Failure.self) { try await browser.open("https://example.com", checkCancellation: false) }
    }
    #expect(recorder.calls.isEmpty)
  }

  @Test func browserLaunchesWhenApplicationIsNotRunning() async throws {
    let recorder = BrowserRecorder()
    let mock = Open.System.Mock(openDefault: { recorder.add("default:\($0.absoluteString)"); return false }, firstRunningProcess: { _ in nil })
    let browser = Open.Browser(environment: .testing, tabSearch: Open.BrowserTabSearch { _, _, _ in
      recorder.add("script"); return nil
    }, raiseMatchingWindow: { _, _ in recorder.add("ax"); return false })
    try await Open.System.Testing.$mock.withValue(mock) {
      try await browser.open("https://example.com", checkCancellation: false)
    }
    #expect(recorder.calls == ["default:https://example.com"])
  }

  @Test func browserLaunchesExplicitApplicationWhenNotRunning() async throws {
    let recorder = BrowserRecorder()
    let mock = Open.System.Mock(
      open: { url, app in recorder.add("open:\(url.absoluteString):\(app?.path ?? "nil")") },
      firstRunningProcess: { recorder.add("lookup:\($0)"); return nil }
    )
    let browser = Open.Browser(environment: .testing, tabSearch: Open.BrowserTabSearch { _, _, _ in
      recorder.add("script"); return nil
    }, raiseMatchingWindow: { _, _ in recorder.add("ax"); return false })
    let app = Open.TargetApplication(bundleIdentifier: "browser.id", bundleName: "Browser", displayName: "Browser", path: "/Browser.app")
    try await Open.System.Testing.$mock.withValue(mock) {
      try await browser.open("https://example.com", application: app, checkCancellation: false)
    }
    #expect(recorder.calls == ["lookup:browser.id", "open:https://example.com:/Browser.app"])
  }
#endif

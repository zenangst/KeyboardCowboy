import Foundation
@testable import OpenFeature
import Testing

#if DEBUG
  private actor CompositionRecorder {
    var events: [String] = []
    func add(_ value: String) { events.append(value) }
  }

  private func composedExecutor(_ recorder: CompositionRecorder) -> Open.Executor {
    let finder = Open.Finder { name, source, cancellation in
      await recorder.add("finder:\(name):\(cancellation):\(source.contains("front Finder window"))")
    }
    let operations = Open.Operations(
      finder: finder,
      generic: Open.Generic(environment: .testing),
      openHost: { await recorder.add("host") },
      openBrowser: { _, _, _ in throw BrowserError.failed },
      openWebApp: { _, _, _ in await recorder.add("web") }
    )
    return Open.Executor(hostBundleIdentifier: "host", hostBundleURL: URL(fileURLWithPath: "/host.app"), operations: operations)
  }

  private enum BrowserError: Error { case failed }

  @Test func composedExecutorUsesFinderGenericAndBrowserFallback() async throws {
    let recorder = CompositionRecorder()
    let mock = Open.System.Mock(open: { url, app in await recorder.add("open:\(url.absoluteString):\(app?.path ?? "default")") })
    let finder = Open.TargetApplication(bundleIdentifier: "com.apple.finder", bundleName: "Finder", displayName: "Finder", path: "/Finder.app")
    let executor = composedExecutor(recorder)
    try await Open.System.Testing.$mock.withValue(mock) {
      try await executor.run("/folder", application: finder, checkCancellation: true)
      try await executor.run("/file", checkCancellation: false)
      try await executor.run("https://example.com", checkCancellation: false)
      try await executor.run("/anything", application: Open.TargetApplication(bundleIdentifier: "host", bundleName: "Host", displayName: "Host", path: "/host.app"), checkCancellation: true)
    }
    #expect(await recorder.events == [
      "finder:Open folder in Finder: /folder:true:true",
      "open:\(URL(fileURLWithPath: "/file").absoluteString):default",
      "open:https://example.com:default",
      "host",
    ])
  }

  @Test func composedExecutorUsesMetadataForFinderRetry() async throws {
    let recorder = CompositionRecorder()
    let mock = Open.System.Mock(isDirectory: { $0 == "https://example.com" })
    let target = Open.TargetApplication(bundleIdentifier: "other", bundleName: "Finder", displayName: "Finder", path: "/Finder.app")
    try await Open.System.Testing.$mock.withValue(mock) {
      try await composedExecutor(recorder).run("https://example.com", application: target, checkCancellation: false)
    }
    #expect(await recorder.events == ["finder:Open folder in Finder: https://example.com:false:true"])
  }
#endif

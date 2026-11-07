import Foundation
import OpenFeature
import Testing

private enum TestError: Error { case failed }

private actor Operations: OpenOperations {
  var calls: [String] = []
  let failures: Set<String>
  let directory: Bool

  init(failures: Set<String> = [], directory: Bool = false) {
    self.failures = failures
    self.directory = directory
  }

  private func record(_ name: String) throws {
    calls.append(name)
    if failures.contains(name) { throw TestError.failed }
  }

  func openHost() { calls.append("host") }
  func openFinder(_ path: String, checkCancellation: Bool) throws { try record("finder:\(path):\(checkCancellation)") }
  func openBrowser(_ path: String, application: OpenTargetApplication?, checkCancellation: Bool) throws {
    try record("browser:\(path):\(application?.bundleIdentifier ?? "default"):\(checkCancellation)")
  }
  func openWebApp(_ path: String, application: OpenTargetApplication, checkCancellation: Bool) throws {
    try record("web:\(path):\(application.bundleIdentifier):\(checkCancellation)")
  }
  func openGeneric(_ path: String, application: OpenTargetApplication?) throws {
    try record("generic:\(path):\(application?.bundleIdentifier ?? "default")")
  }
  func isDirectory(_ path: String) throws -> Bool {
    try record("metadata:\(path)")
    return directory
  }
}

private func executor(_ operations: Operations) -> OpenExecutor {
  OpenExecutor(hostBundleIdentifier: "host", hostBundleURL: URL(fileURLWithPath: "/host.app"), operations: operations)
}

private func target(_ id: String, name: String = "App") -> OpenTargetApplication {
  OpenTargetApplication(bundleIdentifier: id, bundleName: name, displayName: "Display", path: "/app")
}

@Test func hostInterceptionHasNoOtherEffects() async throws {
  let operations = Operations()
  try await executor(operations).run("https://example.com", application: target("host"), checkCancellation: true)
  #expect(await operations.calls == ["host"])
}

@Test func routeOperationsReceiveOriginalArguments() async throws {
  let operations = Operations()
  let runner = executor(operations)
  try await runner.run("https://example.com", checkCancellation: true)
  try await runner.run("https://example.com", application: target("com.apple.Safari.WebApp.1"), checkCancellation: false)
  try await runner.run("/folder", application: target("com.apple.finder"), checkCancellation: true)
  try await runner.run("custom:value", application: target("other"), checkCancellation: false)
  #expect(await operations.calls == ["browser:https://example.com:default:true", "web:https://example.com:com.apple.Safari.WebApp.1:false", "finder:/folder:true", "generic:custom:value:other"])
}

@Test func errorsUseLegacyFinderRetryAndDoNotRecurse() async {
  let operations = Operations(failures: ["finder:/folder:true"], directory: true)
  do {
    try await executor(operations).run("/folder", application: target("com.apple.finder", name: "Finder"), checkCancellation: true)
    Issue.record("Expected retry failure")
  } catch {}
  #expect(await operations.calls == ["finder:/folder:true", "metadata:/folder", "finder:/folder:true"])
}

@Test func metadataFailureFallsBackToGeneric() async throws {
  let operations = Operations(failures: ["browser:https://example.com:other:true", "metadata:https://example.com"])
  try await executor(operations).run("https://example.com", application: target("other", name: "Finder"), checkCancellation: true)
  #expect(await operations.calls == ["browser:https://example.com:other:true", "metadata:https://example.com", "generic:https://example.com:other"])
}

@Test func genericFailureIsRetriedOnceAndPropagated() async {
  let operations = Operations(failures: ["generic:/file:default"])
  do {
    try await executor(operations).run("/file", checkCancellation: false)
    Issue.record("Expected generic failure")
  } catch {}
  #expect(await operations.calls == ["generic:/file:default", "metadata:/file", "generic:/file:default"])
}

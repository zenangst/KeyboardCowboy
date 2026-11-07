import CowboyCore
import Foundation
import OpenFeature
import Testing

private actor AdapterRecorder {
  var path: String?
  var application: Open.TargetApplication?
  var checkCancellation: Bool?
  func record(_ path: String, _ application: Open.TargetApplication?, _ cancellation: Bool) {
    self.path = path
    self.application = application
    self.checkCancellation = cancellation
  }
}

@Test func commandAdapterForwardsResolvedPathAndSavedApplication() async throws {
  let json = #"{"application":{"bundleIdentifier":"browser.id","bundleName":"Browser","displayName":"Custom Name","path":"/Apps/Browser.app"},"path":"${url}","meta":{"id":"id","name":"","enabled":false}}"#
  let command = try JSONDecoder().decode(Command.Open.self, from: Data(json.utf8))
  let recorder = AdapterRecorder()
  let operations = Open.Operations(
    openHost: {}, openFinder: { _, _ in },
    openBrowser: { await recorder.record($0, $1, $2) },
    openWebApp: { _, _, _ in }, openGeneric: { _, _ in }, isDirectory: { _ in false }
  )
  let executor = Open.Executor(hostBundleIdentifier: "host", hostBundleURL: URL(fileURLWithPath: "/host.app"), operations: operations)
  try await executor.run(command, resolvedPath: "https://example.com", checkCancellation: true)
  #expect(await recorder.path == "https://example.com")
  #expect(await recorder.application == Open.TargetApplication(bundleIdentifier: "browser.id", bundleName: "Browser", displayName: "Custom Name", path: "/Apps/Browser.app"))
  #expect(await recorder.checkCancellation == true)
  #expect(command.path == "${url}")
}

@Test func commandAdapterForwardsAbsentApplication() async throws {
  let recorder = AdapterRecorder()
  let operations = Open.Operations(
    openHost: {}, openFinder: { _, _ in }, openBrowser: { _, _, _ in }, openWebApp: { _, _, _ in },
    openGeneric: { await recorder.record($0, $1, false) }, isDirectory: { _ in false }
  )
  let executor = Open.Executor(hostBundleIdentifier: "host", hostBundleURL: URL(fileURLWithPath: "/host.app"), operations: operations)
  try await executor.run(Command.Open(path: "original"), resolvedPath: "/resolved path", checkCancellation: false)
  #expect(await recorder.path == "/resolved path")
  #expect(await recorder.application == nil)
}

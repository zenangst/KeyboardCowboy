import Foundation
import OpenFeature
import Testing

private func application(_ id: String) -> Open.TargetApplication {
  Open.TargetApplication(bundleIdentifier: id, bundleName: "Name", displayName: "Display", path: "/Applications/App.app")
}

@Test(arguments: [
  ("/tmp/a file", "com.apple.finder", Open.Dispatcher.Route.finder),
  ("https://example.com", "COM.APPLE.FINDER", .finder),
  ("https://example.com", "com.apple.Safari.WebApp.123", .webApp),
  ("https://example.com", "com.kagi.kagimacOS.WebApp.123", .webApp),
  ("/tmp/file", "com.apple.Safari.WebApp.123", .generic),
  ("https://example.com", "other", .browser),
  ("custom://example.com", "other", .browser),
  ("custom:value", "other", .generic),
  ("file:///tmp/file", "other", .generic),
  ("http://[", "other", .generic),
  ("https://example.com", "host.id", .host),
])
func selectsPrimaryRoute(path: String, id: String, expected: Open.Dispatcher.Route) {
  let dispatcher = Open.Dispatcher(hostBundleIdentifier: "host.id", hostBundleURL: URL(fileURLWithPath: "/host.app"))
  #expect(dispatcher.route(path: path, application: application(id)) == expected)
}

@Test func hostPathPrecedesFinderAndResolvesSymlinksAndTilde() throws {
  let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: directory) }
  let host = directory.appendingPathComponent("Host.app")
  try FileManager.default.createDirectory(at: host, withIntermediateDirectories: true)
  let link = directory.appendingPathComponent("Link.app")
  try FileManager.default.createSymbolicLink(at: link, withDestinationURL: host)
  let dispatcher = Open.Dispatcher(hostBundleIdentifier: "host.id", hostBundleURL: host)
  #expect(dispatcher.route(path: link.path, application: application("com.apple.finder")) == .host)
  #expect(dispatcher.route(path: host.appendingPathComponent("../Host.app").path) == .host)

  let home = FileManager.default.homeDirectoryForCurrentUser
  let homeDispatcher = Open.Dispatcher(hostBundleIdentifier: "host.id", hostBundleURL: home)
  #expect(homeDispatcher.route(path: "~") == .host)
  #expect(dispatcher.route(path: "/elsewhere", application: application("other")) == .generic)
}

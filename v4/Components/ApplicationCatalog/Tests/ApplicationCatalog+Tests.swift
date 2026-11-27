@testable import ApplicationCatalog
import Foundation
import Testing

@Test func legacyApplicationCodingAndIdentity() throws {
  let data = Data(#"""
  {"bundleIdentifier":"com.example.app","bundleName":"Name","path":"/Applications/Name.app",
   "metadata":{"isAgent":true,"isElectron":false,"isSafariWebApp":false}}
  """#.utf8)
  let app = try JSONDecoder().decode(ApplicationCatalog.Application.self, from: data)
  #expect(app.displayName == FileManager.default.displayName(atPath: app.path))
  #expect(app.metadata.isAgent)
  let encoded = try JSONEncoder().encode(app)
  let json = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
  #expect(Set(json.keys) == ["bundleIdentifier", "bundleName", "path", "displayName"])

  var renamed = app
  renamed.displayName = "New name"
  renamed.metadata.isAgent = false
  #expect(app == renamed)
  #expect(Set([app, renamed]).count == 1)
}

@Test func scanSkipsMissingRootsAndOrdinaryBundleContentsButFindsXcodeTools() throws {
  let files = FileManager.default
  let root = files.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
  try files.createDirectory(at: root, withIntermediateDirectories: true)
  defer { try? files.removeItem(at: root) }

  let group = root.appending(path: "Group", directoryHint: .isDirectory)
  let webApp = try makeApp(in: root, at: "Group/alpha tool.app", identifier: "com.apple.Safari.WebApp.test",
                           extra: ["LSUIElement": true])
  try files.createDirectory(at: webApp.appending(path: "Contents/Frameworks/Electron Framework.framework"),
                            withIntermediateDirectories: true)
  try makeApp(in: root, at: "Bravo.app", identifier: "com.example.bravo")
  try makeApp(in: root, at: "Bravo.app/Contents/Xcode Helper.app", identifier: "com.example.hidden")
  try makeApp(in: root, at: "Group/Deeper/Hidden.app", identifier: "com.example.deep")
  try makeApp(in: root, at: "Xcode.app", identifier: "com.apple.dt.Xcode")
  try makeApp(in: root, at: "Xcode.app/Contents/Applications/Instruments.app",
              identifier: "com.apple.dt.Instruments")
  try makeApp(in: root, at: "Invalid.app", identifier: "com.example.invalid", hasIcon: false)

  #expect(!ApplicationCatalog.scan([root]).contains { $0.bundleIdentifier == "com.example.deep" })
  let apps = ApplicationCatalog.scan([root.appending(path: "Missing"), root, group, root])
  #expect(apps.map(\.bundleIdentifier) == [
    "com.apple.Safari.WebApp.test",
    "com.example.bravo",
    "com.example.deep",
    "com.apple.dt.Instruments",
    "com.apple.dt.Xcode",
  ])
  let first = try #require(apps.first)
  #expect(first.path == webApp.path)
  #expect(first.metadata.isAgent)
  #expect(first.metadata.isElectron)
  #expect(first.metadata.isSafariWebApp)
}

@discardableResult
private func makeApp(
  in root: URL, at path: String, identifier: String,
  hasIcon: Bool = true, extra: [String: Any] = [:],
) throws -> URL {
  let app = root.appending(path: path, directoryHint: .isDirectory)
  let contents = app.appending(path: "Contents", directoryHint: .isDirectory)
  try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)
  var info = extra
  info["CFBundleIdentifier"] = identifier
  info["CFBundleName"] = app.deletingPathExtension().lastPathComponent
  info["CFBundlePackageType"] = "APPL"
  if hasIcon { info["CFBundleIconFile"] = "AppIcon" }
  let data = try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
  try data.write(to: contents.appending(path: "Info.plist"))
  return app
}

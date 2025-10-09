import Cocoa
import Combine

final class JXAPlugin: @unchecked Sendable {
  private let bundleIdentifier = Bundle.main.bundleIdentifier!

  let shellScript = ShellScriptPlugin()
  let fileManager: FileManager

  init(_ fileManager: FileManager = .default) {
    self.fileManager = fileManager
  }

  func execute(_ source: String, withId id: String, environment: [String: String], checkCancellation: Bool) async throws -> String? {
    let url = try createTmpDirectory()
    let data = source.data(using: .utf8)

    _ = fileManager.createFile(atPath: url.path, contents: data, attributes: nil)

    let output = try await executeScript(at: url.path(), withId: id,
                                         environment: environment,
                                         checkCancellation: checkCancellation)

    try fileManager.removeItem(atPath: url.path)
    return output
  }

  func executeScript(at path: String, withId _: String, environment: [String: String], checkCancellation _: Bool) async throws -> String? {
    let source = """
    osascript -l JavaScript \(path)
    """

    let output = try await shellScript.executeScript(source,
                                                     environment: environment,
                                                     checkCancellation: true)
    return output
  }

  private func createTmpDirectory() throws -> URL {
    let tmpName = UUID().uuidString
    let tmpDirectory = NSTemporaryDirectory()
    var url = URL(fileURLWithPath: tmpDirectory)
    url.appendPathComponent(Bundle.main.bundleIdentifier!)

    try fileManager.createDirectory(at: url, withIntermediateDirectories: true)

    url.appendPathComponent(tmpName)

    return url
  }
}

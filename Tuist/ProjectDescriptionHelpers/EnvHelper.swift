import Foundation
import ProjectDescription

public struct EnvHelper: Sendable {
  private let dictionary: [String: String]

  public subscript(key: String) -> SettingValue { SettingValue(stringLiteral: dictionary[key]!) }

  public init(_ path: String) {
    let fileManager = FileManager.default
    var env = [String: String]()

    if fileManager.fileExists(atPath: path) {
      guard let data = fileManager.contents(atPath: path) else { fatalError("🌈 unable to read .env: \(path)") }
      guard let contents = String(data: data, encoding: .utf8) else { fatalError("🌈 Unable to read data at path: \(path)") }

      let lines = contents
        .components(separatedBy: .newlines)
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .filter { $0.first != "#" }
        .filter { $0.contains("=") }

      lines.forEach { line in
        let components = line.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: true)
        if components.count == 2 {
          let name = String(components[0])
          let value = String(components[1])
          env[name] = value
        }
      }
    } else {
      env = [
        "APP_NAME" : "Keyboard Cowboy",
        "APP_SCHEME" : "Keyboard-Cowboy",
        "APP_BUNDLE_IDENTIFIER" : "com.zenangst.Keyboard-Cowboy",
        "TEAM_ID" : "XXXXXXXXXX",
        "PACKAGE_DEVELOPMENT" : "false",
      ]
    }

    self.dictionary = env
  }
}

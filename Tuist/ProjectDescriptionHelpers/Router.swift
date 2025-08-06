import Foundation

public struct Router {
  public static let sourceRoot = URL(fileURLWithPath: String(#filePath))
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .absoluteString
    .replacingOccurrences(of: "file://", with: "")
  public static let assetPath = sourceRoot.appending("Assets")
  public static let envPath = sourceRoot.appending(".env")
}

import Foundation

var rootFolder: String {
  if let sourceRoot = ProcessInfo.processInfo.environment["SOURCE_ROOT"] {
    sourceRoot
  } else {
    String(URL(fileURLWithPath: #file).pathComponents
      .prefix(while: { $0 != "KeyboardCowboy" })
      .joined(separator: "/")
      .dropFirst())
  }
}

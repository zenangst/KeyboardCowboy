import Foundation

@MainActor final class Debugger: ObservableObject {
  enum Context: String, CaseIterable {
    case commandError
    case event
    case machPortFailure
    case shortcutResolver

    var displayValue: String {
      switch self {
      case .commandError: "Command Errors"
      case .event: "Events"
      case .machPortFailure: "Mach Port Failures"
      case .shortcutResolver: "Shortcut Resolver"
      }
    }
  }

  @Published var enabledContexts: [Context] = []
  private let fileManager = FileManager.default
  private let path: URL

  static let shared = Debugger()

  init() {
    let url = URL(filePath: "~/.config/keyboardcowboy")
    let filePath = url.appending(path: "debug.log")
    self.path = filePath

    if !fileManager.fileExists(atPath: path.absoluteString) {
      fileManager.createFile(atPath: path.absoluteString, contents: nil)
    }
  }

  func log(functionName: StaticString = #function,
           filePath: StaticString = #fileID, lineNumber: UInt = #line,
           _ context: Context, _ message: @autoclosure () -> String) {
    guard enabledContexts.contains(context) else { return }

    let prefix = "\(filePath).\(functionName):\(lineNumber)"
    let output = "\(Date())\t\(context.rawValue)\t\(prefix) | \(message())\n"

    try? fileManager.append(output, to: path)
  }
}

extension FileManager {
  func append(_ string: String, to url: URL) throws {
    let data = Data(string.utf8)

    if fileExists(atPath: url.path) {
      let handle = try FileHandle(forWritingTo: url)
      defer { try? handle.close() }

      try handle.seekToEnd()
      try handle.write(contentsOf: data)
    } else {
      try data.write(to: url, options: .atomic)
    }
  }
}

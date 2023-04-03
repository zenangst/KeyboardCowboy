import Foundation

final class FileLogger {
  private static let rootPath = URL(fileURLWithPath: #file).pathComponents
    .prefix(while: { $0 != "App" })
    .joined(separator: "/")


  static func log(_ statement: @autoclosure () -> String) {
//    guard launchArguments.isEnabled(.fileLogging) else { return }

    let path = rootPath.appending("/_ignored")
    let logFile = URL(filePath: path.appending("/console.log"))
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    let timestamp = formatter.string(from: Date())
    guard let data = (timestamp + ": " + statement() + "\n").data(using: String.Encoding.utf8) else { return }

    if FileManager.default.fileExists(atPath: logFile.path) {
      if let fileHandle = try? FileHandle(forWritingTo: logFile) {
        fileHandle.seekToEndOfFile()
        fileHandle.write(data)
        fileHandle.closeFile()
      }
    } else {
      try? data.write(to: logFile, options: .atomicWrite)
    }
  }
}

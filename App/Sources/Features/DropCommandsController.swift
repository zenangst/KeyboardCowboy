import Foundation
import ModelKit

class DropCommandsController {
  static func generateCommands(from urls: [URL],
                               applications: [Application]) -> [Command] {
    var commands = [Command]()
    for url in urls {
      switch url.dropType {
      case .application:
        guard let application = applications.first(where: { $0.path == url.path })
        else { continue }
        let applicationCommand = ApplicationCommand(
          name: "Open \(application.bundleName)",
          application: application)
        commands.append(Command.application(applicationCommand))
      case .applescript:
        let name = "Run \(url.lastPathComponent)"
        commands.append(Command.script(.appleScript(id: UUID().uuidString,
                                                    name: name, source: .path(url.path))))
      case .shellscript:
        let name = "Run \(url.lastPathComponent)"
        commands.append(Command.script(.shell(id: UUID().uuidString,
                                              name: name, source: .path(url.path))))
      case .file:
        let name = "Open \(url.lastPathComponent)"
        commands.append(Command.open(.init(name: name, path: url.path)))
      case .web:
        var name = "Open URL"
        if let scheme = url.scheme {
          name = "Open \(url.absoluteString.replacingOccurrences(of: "\(scheme)://", with: ""))"
        }
        commands.append(Command.open(.init(name: name, path: url.absoluteString)))
      case .unsupported:
        continue
      }
    }
    return commands
  }
}

private enum DropType {
  case application
  case applescript
  case shellscript
  case file
  case web
  case unsupported
}

private extension URL {
  var dropType: DropType {
    if isFileURL {
      if lastPathComponent.contains(".app") {
        return .application
      } else if lastPathComponent.contains(".sh") {
        return .shellscript
      } else if lastPathComponent.contains(".scpt") {
        return .applescript
      } else {
        return .file
      }
    } else {
      return .web
    }
  }
}

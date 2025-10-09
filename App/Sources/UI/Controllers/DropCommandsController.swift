import Apps
import Foundation

// TODO: Add support for defaults: Notification (true/false)
enum DropCommandsController {
  static func generateCommands(from urls: [URL], applications: [Application]) -> [Command] {
    var commands = [Command]()
    for url in urls {
      switch url.dropType {
      case .application:
        guard let application = applications.first(where: { $0.path == url.path })
        else { continue }

        let applicationCommand = ApplicationCommand(
          name: "\(application.bundleName)",
          application: application,
          notification: nil,
        )
        commands.append(Command.application(applicationCommand))
      case .applescript:
        let name = "\(url.lastPathComponent)"
        let command = Command.script(.init(name: name, kind: .appleScript(variant: .regular), source: .path(url.path), notification: nil))
        commands.append(command)
      case .shellscript:
        let name = "\(url.lastPathComponent)"
        let command = Command.script(.init(name: name, kind: .shellScript, source: .path(url.path), notification: nil))
        commands.append(command)
      case .file:
        let name = "\(url.lastPathComponent)"
        commands.append(Command.open(.init(name: name, path: url.path, notification: nil)))
      case .web:
        var name = "URL"
        if let scheme = url.scheme {
          name = "\(url.absoluteString.replacingOccurrences(of: "\(scheme)://", with: ""))"
        }
        commands.append(Command.open(.init(name: name, path: url.absoluteString, notification: nil)))
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
        .application
      } else if lastPathComponent.contains(".sh") {
        .shellscript
      } else if lastPathComponent.contains(".scpt") {
        .applescript
      } else {
        .file
      }
    } else {
      .web
    }
  }
}

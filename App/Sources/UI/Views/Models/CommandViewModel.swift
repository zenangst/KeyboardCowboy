import Apps
import Foundation

struct CommandViewModel: Codable, Hashable, Identifiable {
  struct MetaData: Identifiable, Codable, Hashable, Sendable {
    var id: String
    var delay: Double?
    var name: String
    var namePlaceholder: String
    var isEnabled: Bool
    var notification: Bool
    var icon: IconViewModel?
  }

  var id: String { meta.id }
  var meta: MetaData
  var kind: Kind

  enum Kind: Codable, Hashable, Identifiable, Sendable {
    var id: String {
      switch self {
      case .application(let applicationModel):
        return applicationModel.id
      case .open(let openModel):
        return openModel.id
      case .keyboard(let keyboardModel):
        return keyboardModel.id
      case .script(let scriptModel):
        return scriptModel.id
      case .plain:
        return UUID().uuidString
      case .shortcut(let shortcutModel):
        return shortcutModel.id
      case .type(let typeModel):
        return typeModel.id
      case .systemCommand(let systemModel):
        return systemModel.id
      case .menuBar(let menuBarModel):
        return menuBarModel.id
      }
    }

    case application(ApplicationModel)
    case open(OpenModel)
    case keyboard(KeyboardModel)
    case script(ScriptModel)
    case plain
    case shortcut(ShortcutModel)
    case type(TypeModel)
    case systemCommand(SystemModel)
    case menuBar(MenuBarModel)

    struct ApplicationModel: Codable, Hashable, Identifiable, Sendable {
      let id: String
      var action: String
      var inBackground: Bool
      var hideWhenRunning: Bool
      var ifNotRunning: Bool
    }

    struct OpenModel: Codable, Hashable, Identifiable, Sendable {
      let id: String
      var path: String
      var applicationPath: String?
      var appName: String?
      var applications: [Application]
    }

    struct KeyboardModel: Codable, Hashable, Identifiable, Sendable {
      let id: String
      var keys: [KeyShortcut]
    }

    struct MenuBarModel: Codable, Hashable, Identifiable, Sendable {
      let id: String
      var tokens: [MenuBarCommand.Token]
    }

    struct ScriptModel: Codable, Hashable, Identifiable, Sendable {
      let id: String
      var source: ScriptCommand.Source
      var scriptExtension: ScriptCommand.Kind
    }

    struct ShortcutModel: Codable, Hashable, Identifiable, Sendable {
      let id: String
      var shortcutIdentifier: String
    }

    struct SystemModel: Codable, Hashable, Identifiable, Sendable {
      let id: String
      var kind: SystemCommand.Kind
    }

    struct TypeModel: Codable, Hashable, Identifiable, Sendable {
      let id: String
      var input: String
    }
  }
}

import Apps
import Bonzai
import Foundation

struct CommandViewModel: Codable, Hashable, Identifiable {
  struct MetaData: Identifiable, Codable, Hashable, Sendable {
    var id: String
    var delay: Double?
    var name: String
    var namePlaceholder: String
    var isEnabled: Bool
    var notification: Bool
    var icon: Icon?

    init(id: String = UUID().uuidString,
         delay: Double? = nil,
         name: String,
         namePlaceholder: String,
         isEnabled: Bool = true,
         notification: Bool = false,
         icon: Icon? = nil) {
      self.id = id
      self.delay = delay
      self.name = name
      self.namePlaceholder = namePlaceholder
      self.isEnabled = isEnabled
      self.notification = notification
      self.icon = icon
    }
  }

  var id: String { meta.id }
  var meta: MetaData
  var kind: Kind

  enum Kind: Codable, Hashable, Identifiable, Sendable {
    var id: String { (self as (any Identifiable<String>)).id }

    case application(ApplicationModel)
    case open(OpenModel)
    case keyboard(KeyboardModel)
    case script(ScriptModel)
    case plain
    case shortcut(ShortcutModel)
    case text(TextModel)
    case systemCommand(SystemModel)
    case menuBar(MenuBarModel)
    case mouse(MouseModel)
    case windowManagement(WindowManagementModel)

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

    struct MouseModel: Codable, Hashable, Identifiable, Sendable {
      let id: String
      var kind: MouseCommand.Kind
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
      var mode: TextCommand.TypeCommand.Mode
      var input: String
    }

    struct TextModel: Codable, Hashable, Identifiable, Sendable {
      var id: String { kind.id }

      let kind: Kind

      enum Kind: Codable, Hashable, Identifiable, Sendable {
        var id: String {
          switch self {
          case .type(let model):      model.id
          }
        }

        case type(TypeModel)
      }
    }

    struct WindowManagementModel: Codable, Hashable, Identifiable, Sendable {
      let id: String
      var kind: WindowCommand.Kind
      var animationDuration: Double
    }
  }
}

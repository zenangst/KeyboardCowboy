import Apps
import Bonzai
import CoreTransferable
import Foundation

struct CommandViewModel: Codable, Hashable, Identifiable, Transferable {
  static var transferRepresentation: some TransferRepresentation {
    CodableRepresentation(contentType: .command)
  }

  struct MetaData: Identifiable, Codable, Hashable, Sendable {
    var id: String
    var delay: Double?
    var name: String
    var namePlaceholder: String
    var isEnabled: Bool
    var notification: Command.Notification?
    var icon: Icon?
    var variableName: String

    init(id: String = UUID().uuidString,
         delay: Double? = nil,
         name: String,
         namePlaceholder: String,
         isEnabled: Bool = true,
         notification: Command.Notification? = nil,
         icon: Icon? = nil,
         variableName: String = "") {
      self.id = id
      self.delay = delay
      self.name = name
      self.namePlaceholder = namePlaceholder
      self.isEnabled = isEnabled
      self.notification = notification
      self.icon = icon
      self.variableName = variableName
    }
  }

  var id: String { meta.id }
  var meta: MetaData
  var kind: Kind

  enum Kind: Codable, Hashable, Identifiable, Sendable {
    var id: String { (self as (any Identifiable<String>)).id }

    case application(ApplicationModel)
    case builtIn(BuiltInModel)
    case bundled(BundledModel)
    case open(OpenModel)
    case keyboard(KeyboardModel)
    case script(ScriptModel)
    case shortcut(ShortcutModel)
    case text(TextModel)
    case systemCommand(SystemModel)
    case menuBar(MenuBarModel)
    case mouse(MouseModel)
    case uiElement(UIElementCommand)
    case windowManagement(WindowManagementModel)

    struct ApplicationModel: Codable, Hashable, Identifiable, Sendable {
      let id: String
      var placheolder: String { "Open/Close/Switch to Application …" }
      var action: String
      var inBackground: Bool
      var hideWhenRunning: Bool
      var ifNotRunning: Bool
      var addToStage: Bool
      var waitForAppToLaunch: Bool
    }

    struct BuiltInModel: Codable, Hashable, Identifiable, Sendable {
      let id: String
      var name: String
      var placeholder: String { "Run Built-In Action …" }
      var kind: BuiltInCommand.Kind
    }

    struct BundledModel: Codable, Hashable, Identifiable, Sendable {
      enum Kind: Codable, Hashable, Sendable {
        case workspace(WorkspaceModel)
        case appFocus(AppFocusModel)
      }
      let id: String
      var name: String
      var placeholder: String { "Open Bundled View …" }
      let kind: Kind
    }

    struct WorkspaceModel: Codable, Hashable, Sendable {
      var applications: [Application]
      var tiling: WorkspaceCommand.Tiling?
      var hideOtherApps: Bool
    }

    struct AppFocusModel: Codable, Hashable, Sendable {
      var placheholder: String { "Focus on App …" }
      var application: Application?
      var tiling: WorkspaceCommand.Tiling?
      var hideOtherApps: Bool
      var createNewWindow: Bool
    }

    struct OpenModel: Codable, Hashable, Identifiable, Sendable {
      let id: String
      var placheolder: String { "Open …" }
      var path: String
      var applicationPath: String?
      var appName: String?
      var applications: [Application]
    }

    struct KeyboardModel: Codable, Hashable, Identifiable, Sendable {
      let id: String
      var placeholder: String { "Invoke Keyboard Shortcut …" }
      var iterations: Int
      var keys: [KeyShortcut]
    }

    struct MouseModel: Codable, Hashable, Identifiable, Sendable {
      let id: String
      var placeholder: String { "Control Mouse …" }
      var kind: MouseCommand.Kind
    }

    struct MenuBarModel: Codable, Hashable, Identifiable, Sendable {
      let id: String
      var placeholder: String { "Click MenuBar Item …" }
      var application: Application?
      var tokens: [MenuBarCommand.Token]

      init(id: String, application: Application? = nil, tokens: [MenuBarCommand.Token]) {
        self.id = id
        self.application = application
        self.tokens = tokens
      }
    }

    struct ScriptModel: Codable, Hashable, Identifiable, Sendable {
      let id: String
      var placeholder: String { "Run Script …" }
      var source: ScriptCommand.Source
      var scriptExtension: ScriptCommand.Kind
      var variableName: String
      var execution: Workflow.Execution
    }

    struct ShortcutModel: Codable, Hashable, Identifiable, Sendable {
      let id: String
      var placeholder: String { "Run Shortcut …" }
      var shortcutIdentifier: String
    }

    struct SystemModel: Codable, Hashable, Identifiable, Sendable {
      let id: String
      var placeholder: String { "Run System Shortcut …" }
      var kind: SystemCommand.Kind
    }

    struct TypeModel: Codable, Hashable, Identifiable, Sendable {
      let id: String
      var mode: TextCommand.TypeCommand.Mode
      var placeholder: String { "Type input …" }
      var input: String
    }

    struct TextModel: Codable, Hashable, Identifiable, Sendable {
      var id: String { kind.id }
      var placeholder: String {
        switch kind {
        case .type(let model): model.placeholder
        }
      }
      let kind: Kind

      enum Kind: Codable, Hashable, Identifiable, Sendable {
        var id: String {
          switch self {
          case .type(let model): model.id
          }
        }

        case type(TypeModel)
      }
    }

    struct WindowManagementModel: Codable, Hashable, Identifiable, Sendable {
      let id: String
      var placeholder: String { "Control Window…" }
      var kind: WindowCommand.Kind
      var animationDuration: Double
    }
  }
}

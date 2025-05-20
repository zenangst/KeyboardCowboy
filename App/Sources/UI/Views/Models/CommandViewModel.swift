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
    var placeholder: String {
      switch self {
      case .application(let applicationModel): applicationModel.placeholder
      case .builtIn(let builtInModel): builtInModel.placeholder
      case .bundled(let bundledModel): bundledModel.placeholder
      case .open(let openModel): openModel.placeholder
      case .keyboard(let keyboardModel): keyboardModel.placeholder
      case .inputSource(let inputSourceModel): inputSourceModel.placeholder
      case .script(let scriptModel): scriptModel.placeholder
      case .shortcut(let shortcutModel): shortcutModel.placeholder
      case .text(let textModel): textModel.placeholder
      case .systemCommand(let systemModel): systemModel.placeholder
      case .menuBar(let menuBarModel): menuBarModel.placeholder
      case .mouse(let mouseModel): mouseModel.placeholder
      case .uiElement(let uIElementCommand): uIElementCommand.placeholder
      case .windowFocus(let command): command.placeholder
      case .windowManagement(let windowManagementModel): windowManagementModel.placeholder
      case .windowTiling(let command): command.placeholder
      }
    }

    case application(ApplicationModel)
    case builtIn(BuiltInModel)
    case bundled(BundledModel)
    case open(OpenModel)
    case keyboard(KeyboardModel)
    case inputSource(InputSourceModel)
    case script(ScriptModel)
    case shortcut(ShortcutModel)
    case text(TextModel)
    case systemCommand(SystemModel)
    case menuBar(MenuBarModel)
    case mouse(MouseModel)
    case uiElement(UIElementCommand)
    case windowFocus(WindowFocusModel)
    case windowManagement(WindowManagementModel)
    case windowTiling(WindowTilingModel)

    struct ApplicationModel: Codable, Hashable, Identifiable, Sendable {
      let id: String
      var placeholder: String { "Open/Close/Switch to Application …" }
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
        case activatePreviousWorkspace
        case appFocus(AppFocusModel)
        case tidy(WindowTidyModel)
        case workspace(WorkspaceModel)

        var placeholder: String {
          switch self {
          case .activatePreviousWorkspace: "Activate Previous Workspace…"
          case .appFocus: "Focus on App…"
          case .tidy: "Tidy up Windows…"
          case .workspace: "Organize Apps into Workspace…"
          }
        }
      }
      let id: String
      var name: String
      var placeholder: String { kind.placeholder }
      let kind: Kind
    }

    struct WorkspaceModel: Codable, Hashable, Sendable {
      var applications: [Application]
      var appToggleModifiers: [ModifierKey]
      var defaultForDynamicWorkspace: Bool
      var tiling: WorkspaceCommand.Tiling?
      var hideOtherApps: Bool
      var isDynamic: Bool
    }

    struct AppFocusModel: Codable, Hashable, Sendable {
      var application: Application?
      var tiling: WorkspaceCommand.Tiling?
      var hideOtherApps: Bool
      var createNewWindow: Bool
    }

    struct WindowTidyModel: Codable, Hashable, Sendable {
      var rules: [Rule]

      struct Rule: Codable, Hashable, Sendable {
        let application: Application
        var tiling: WindowTiling
      }
    }

    struct OpenModel: Codable, Hashable, Identifiable, Sendable {
      let id: String
      var placeholder: String { "Open …" }
      var path: String
      var applicationPath: String?
      var appName: String?
      var applications: [Application]
    }

    struct InputSourceModel: Codable, Hashable, Identifiable, Sendable {
      var id: String
      var inputId: String
      var name: String
      var placeholder: String { "Change Input Source …" }
    }

    struct KeyboardModel: Codable, Hashable, Identifiable, Sendable {
      let id: String
      var placeholder: String { "Invoke Keyboard Shortcut …" }
      var command: KeyboardCommand.KeyCommand
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
      var actions: Set<TextCommand.TypeCommand.Action>
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

    struct WindowFocusModel: Codable, Hashable, Identifiable, Sendable {
      let id: String
      var placeholder: String { " Window Tiling…" }
      var kind: WindowFocusCommand.Kind
    }

    struct WindowManagementModel: Codable, Hashable, Identifiable, Sendable {
      let id: String
      var placeholder: String { "Control Window…" }
      var kind: WindowManagementCommand.Kind
      var animationDuration: Double
    }

    struct WindowTilingModel: Codable, Hashable, Identifiable, Sendable {
      let id: String
      var placeholder: String { " Window Tiling…" }
      var kind: WindowTiling
    }

  }
}

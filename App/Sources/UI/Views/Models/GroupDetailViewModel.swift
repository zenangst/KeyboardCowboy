import Bonzai
import SwiftUI

struct GroupDetailViewModel: Identifiable, Hashable, Codable, Sendable, Transferable {
  static var transferRepresentation: some TransferRepresentation {
    CodableRepresentation(contentType: .workflow)
  }

  enum Execution: String, Hashable, Codable {
    case concurrent
    case serial
  }

  enum Trigger: Hashable, Codable {
    case application(String)
    case keyboard(String)
    case snippet(String)
  }

  let id: String
  let groupId: String
  let groupName: String?
  let name: String
  let images: [ImageModel]
  let overlayImages: [ImageModel]
  let trigger: Trigger?
  let badge: Int
  let badgeOpacity: Double
  let isEnabled: Bool
  let execution: Execution

  internal init(id: String, groupId: String,
                groupName: String? = nil, name: String,
                images: [GroupDetailViewModel.ImageModel],
                overlayImages: [GroupDetailViewModel.ImageModel],
                trigger: Trigger? = nil, execution: Execution = .concurrent,
                badge: Int, badgeOpacity: Double, isEnabled: Bool) {
    self.id = id
    self.groupId = groupId
    self.groupName = groupName
    self.name = name
    self.images = images
    self.overlayImages = overlayImages
    self.execution = execution
    self.badge = badge
    self.badgeOpacity = badgeOpacity
    self.trigger = trigger
    self.isEnabled = isEnabled
  }

  struct ImageModel: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let offset: Double
    let kind: Kind

    enum Kind: Hashable, Codable, Sendable {
      case application
      case builtIn(BuiltInCommand.Kind)
      case bundled(Bundled)
      case open
      case inputSource
      case keyboard(String)
      case script(ScriptCommand.Source)
      case plain
      case shortcut
      case text(Text)
      case systemCommand(SystemCommand.Kind)
      case menuBar
      case mouse
      case uiElement
      case windowFocus(WindowFocusCommand.Kind)
      case windowManagement
      case windowTiling(WindowTiling)
      case icon(Icon)

      var searchTerm: String {
        switch self {
        case .application: "application"
        case .builtIn: "builtIn"
        case .bundled: "bundled"
        case .open: "open"
        case .keyboard: "keyboard"
        case .inputSource: "inputSource"
        case .script: "script"
        case .plain: "plain"
        case .shortcut: "shortcut"
        case .text: "text"
        case .systemCommand: "system"
        case .menuBar: "menuBar"
        case .mouse: "mouse"
        case .uiElement: "uiElement"
        case .windowFocus: "windowFocus"
        case .windowManagement: "windowManagement"
        case .windowTiling: "windowTiling"
        case .icon: "icon"
        }
      }

      var match: GroupDetailView.Match.Kind {
        switch self {
        case .application: .application
        case .builtIn: .builtIn
        case .bundled: .bundled
        case .open: .open
        case .inputSource: .inputSource
        case .keyboard: .keyboard
        case .script: .script
        case .plain: .plain
        case .shortcut: .shortcut
        case .text: .text
        case .systemCommand: .systemCommand
        case .menuBar: .menuBar
        case .mouse: .mouse
        case .uiElement: .uiElement
        case .windowFocus: .windowFocus
        case .windowManagement: .windowManagement
        case .windowTiling: .windowTiling
        case .icon: .application
        }
      }
    }

    enum Bundled: Hashable, Codable, Sendable {
      case activatePreviousWorkspace
      case appFocus
      case tidy
      case workspace
    }

    enum Text: Hashable, Codable, Sendable {
      case insertText
    }


    static func builtIn(_ command: Command, kind: BuiltInCommand.Kind, offset: Double) -> Self { .init(id: command.id, offset: offset, kind: .builtIn(kind)) }
    static func bundled(_ command: Command, offset: Double, kind: Bundled) -> Self { .init(id: command.id, offset: offset, kind: .bundled(kind)) }
    static func keyboard(_ command: Command, string: String, offset: Double) -> Self { .init(id: command.id, offset: offset, kind: .keyboard(string)) }
    static func inputSource(_ command: Command, offset: Double) -> Self { .init(id: command.id, offset: offset, kind: .inputSource) }
    static func mouse(_ command: Command, offset: Double) -> Self { .init(id: command.id, offset: offset, kind: .mouse) }
    static func menubar(_ command: Command, offset: Double) -> Self { .init(id: command.id, offset: offset, kind: .menuBar) }
    static func script(_ command: Command, source: ScriptCommand.Source, offset: Double) -> Self { .init(id: command.id, offset: offset, kind: .script(source)) }
    static func shortcut(_ command: Command, offset: Double) -> Self { .init(id: command.id, offset: offset, kind: .shortcut) }
    static func systemCommand(_ command: Command, kind: SystemCommand.Kind, offset: Double) -> Self { .init(id: command.id, offset: offset, kind: .systemCommand(kind)) }
    static func text(_ command: Command, kind: Text, offset: Double) -> Self { .init(id: command.id, offset: offset, kind: .text(kind)) }
    static func uiElement(_ command: Command, offset: Double) -> Self { .init(id: command.id, offset: offset, kind: .uiElement) }
    static func windowFocus(_ command: Command, kind: WindowFocusCommand.Kind, offset: Double) -> Self { .init(id: command.id, offset: offset, kind: .windowFocus(kind)) }
    static func windowManagement(_ command: Command, offset: Double) -> Self { .init(id: command.id, offset: offset, kind: .windowManagement) }
    static func windowTiling(_ command: Command, kind: WindowTiling, offset: Double) -> Self { .init(id: command.id, offset: offset, kind: .windowTiling(kind)) }
  }
}

import Foundation

struct MouseCommand: Identifiable, Codable, MetaDataProviding {
  enum Kind: Codable, Identifiable, Hashable {
    case click(UIElement)
    case doubleClick(UIElement)
    case rightClick(UIElement)

    var id: String { displayValue }
    var element: UIElement {
      get {
        switch self {
        case .click(let uIElement): uIElement
        case .doubleClick(let uIElement): uIElement
        case .rightClick(let uIElement): uIElement
        }
      }
      set {
        switch self {
        case .click: self = .click(newValue)
        case .doubleClick: self = .doubleClick(newValue)
        case .rightClick: self = .rightClick(newValue)
        }
      }
    }

    var displayValue: String {
      var value: String = ""
      let element: UIElement
      switch self {
      case .click(let uIElement):
        value += "Click"
        element = uIElement
      case .doubleClick(let uIElement):
        value += "Double Click"
        element = uIElement
      case .rightClick(let uIElement):
        value += "Right Click"
        element = uIElement
      }
      value += " on \(element.displayValue)"
      return value
    }

    static var allCases: [Kind] {
      [
        .click(.focused(.center)),
        .doubleClick(.focused(.center)),
        .rightClick(.focused(.center)),
      ]
    }
  }

  enum ClickLocation: Identifiable, Hashable, Codable, Equatable {
    var id: String { identifier }

    case topLeading
    case top
    case topTrailing
    case leading
    case center
    case trailing
    case bottomLeading
    case bottom
    case bottomTrailing
    case custom(x: Int, y: Int)

    static let allCases: [ClickLocation] = [
      .topLeading,
      .top,
      .topTrailing,
      .leading,
      .center,
      .trailing,
      .bottomLeading,
      .bottom,
      .bottomTrailing,
      .custom(x: 0, y: 0),
    ]

    var identifier: String {
      switch self {
      case .topLeading: "topLeading"
      case .top: "top"
      case .topTrailing: "topTrailing"
      case .leading: "leading"
      case .center: "center"
      case .trailing: "trailing"
      case .bottomLeading: "bottomLeading"
      case .bottom: "bottom"
      case .bottomTrailing: "bottomTrailing"
      case .custom(let x, let y): "custom:\(x)x\(y)"
      }
    }

    var displayValue: String {
      switch self {
      case .topLeading: "Top Leading"
      case .top: "Top"
      case .topTrailing: "Top Trailing"
      case .leading: "Leading"
      case .center: "Center"
      case .trailing: "Trailing"
      case .bottomLeading: "Bottom Leading"
      case .bottom: "Bottom"
      case .bottomTrailing: "Bottom Trailing"
      case .custom: "Custom"
      }
    }
  }

  enum UIElement: Codable, Hashable, Equatable {
    case focused(ClickLocation)

    var displayValue: String {
      switch self {
      case .focused:
        return "Focused Element"
      }
    }

    var clickLocation: ClickLocation {
      get {
        switch self {
        case .focused(let clickLocation):
          return clickLocation
        }
      }
      set {
        switch self {
        case .focused:
          self = .focused(newValue)
        }
      }
    }
  }

  var meta: Command.MetaData
  var kind: Kind

  func copy() -> MouseCommand {
    MouseCommand(meta: self.meta.copy(), kind: self.kind)
  }

  static func empty() -> MouseCommand {
    .init(meta: .init(), kind: .click(.focused(.center)))
  }
}

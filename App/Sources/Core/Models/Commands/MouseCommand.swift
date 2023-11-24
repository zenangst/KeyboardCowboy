import Foundation

struct MouseCommand: Identifiable, Codable, MetaDataProviding {
  enum Kind: Codable, Identifiable, Hashable {
    case click(UIElement)
    case doubleClick(UIElement)
    case rightClick(UIElement)

    var id: String { displayValue }

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
        .click(.focused),
        .doubleClick(.focused),
        .rightClick(.focused),
      ]
    }
  }

  enum UIElement: Codable {
    case focused

    var displayValue: String {
      switch self {
      case .focused:
        return "Focused Element"
      }
    }
  }

  var meta: Command.MetaData
  var kind: Kind

  static func empty() -> MouseCommand {
    .init(meta: .init(), kind: .click(.focused))
  }
}

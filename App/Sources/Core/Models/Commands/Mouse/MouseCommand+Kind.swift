extension MouseCommand {
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
}

import ApplicationServices

extension UIElementCommand {
  enum Kind: String, Codable, Hashable, CaseIterable {
    case any = "*"
    case button
    case cell
    case link
    case radioButton
    case menuButton
    case popUpButton
    case staticText
    case textArea

    init(_ axValue: String) {
      self = switch axValue {
      case "*": .any
      case kAXButtonRole: .button
      case kAXCellRole: .cell
      case "AXLink": .link
      case kAXRadioButtonRole: .radioButton
      case kAXMenuButtonRole: .menuButton
      case kAXPopUpButtonRole: .popUpButton
      case kAXStaticTextRole: .staticText
      case kAXTextAreaRole: .textArea
      default: .any
      }
    }

    var displayName: String {
      switch self {
      case .any: "Any"
      case .button: "Button"
      case .cell: "Cell"
      case .link: "Link"
      case .menuButton: "Menu Button"
      case .popUpButton: "Pop Up Button"
      case .radioButton: "Radio Button"
      case .staticText: "Static Text"
      case .textArea: "Text Area"
      }
    }

    var axValue: String {
      switch self {
      case .any: "*"
      case .button: kAXButtonRole
      case .cell: kAXCellRole
      case .link: "AXLink"
      case .radioButton: kAXRadioButtonRole
      case .menuButton: kAXMenuButtonRole
      case .popUpButton: kAXPopUpButtonRole
      case .staticText: kAXStaticTextRole
      case .textArea: kAXTextAreaRole
      }
    }
  }
}

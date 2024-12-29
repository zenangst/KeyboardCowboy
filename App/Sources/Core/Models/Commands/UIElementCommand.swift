import ApplicationServices
import Foundation

struct UIElementCommand: MetaDataProviding {
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

  struct Predicate: Identifiable, Codable, Hashable {
    let id: String
    var kind: Kind
    var value: String
    var compare: Compare
    var properties: [Properties]

    enum Compare: Codable, Hashable, CaseIterable {
      case equals
      case contains
      case hasPrefix
      case hasSuffix

      var displayName: String {
        switch self {
        case .equals: "Equals"
        case .contains: "Contains"
        case .hasPrefix: "Has Prefix"
        case .hasSuffix: "Has Suffix"
        }
      }

      func run(lhs: String?, rhs: String) -> Bool {
        guard let lhs else { return false }
        switch self {
        case .equals: return lhs == rhs
        case .contains: return lhs.contains(rhs)
        case .hasPrefix: return lhs.hasPrefix(rhs)
        case .hasSuffix: return lhs.hasSuffix(rhs)
        }
      }
    }

    enum Properties: String, Codable, Hashable, CaseIterable, Identifiable {
      var id: String { rawValue }
      case description
      case identifier
      case title
      case value
      case subrole

      var displayName: String {
        switch self {
        case .identifier: "Identifier"
        case .description: "Description"
        case .title: "Title"
        case .value: "Value"
        case .subrole: "Subrole"
        }
      }

      var axValue: String {
        switch self {
        case .identifier: kAXIdentifierAttribute
        case .description: kAXDescriptionAttribute
        case .title: kAXTitleAttribute
        case .value: kAXValueAttribute
        case .subrole: kAXSubroleAttribute
        }
      }
    }

    init(id: String = UUID().uuidString, value: String,
         compare: Compare = .equals, kind: Kind = .any,
         properties: [Properties] = [.description, .title, .value]) {
      self.id = id
      self.value = value
      self.compare = compare
      self.properties = properties
      self.kind = kind
    }

    func copy() -> Predicate {
      Predicate(value: value, compare: compare, kind: kind, properties: properties)
    }
  }

  var placeholder: String {
    predicates.count > 1 
    ? "Tap on UI Elements …"
    : "Tap on UI Element …"
  }
  var meta: Command.MetaData
  var predicates: [Predicate]

  init(meta: Command.MetaData = .init(), predicates: [Predicate]) {
    self.meta = meta
    self.predicates = predicates
  }

  func copy() -> UIElementCommand {
    UIElementCommand(meta: meta.copy(), predicates: predicates.copy())
  }
}

extension Collection where Element == UIElementCommand.Predicate {
  func copy() -> [UIElementCommand.Predicate] {
    map { $0.copy() }
  }
}

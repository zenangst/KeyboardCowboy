import ApplicationServices
import Foundation

struct UIElementCommand: MetaDataProviding {
  enum Kind: String, Codable, Hashable, CaseIterable {
    case any = "*"
    case button
    case cell
    case radioButton
    case menuButton
    case popUpButton
    case decrementButton
    case incrementButton
    case staticText

    init(_ axValue: String) {
      self = switch axValue {
      case "*": .any
      case kAXButtonRole: .button
      case kAXCellRole: .cell
      case kAXRadioButtonRole: .radioButton
      case kAXMenuButtonRole: .menuButton
      case kAXPopUpButtonRole: .popUpButton
      case kAXDecrementButtonAttribute: .decrementButton
      case kAXIncrementButtonAttribute: .incrementButton
      case kAXStaticTextRole: .staticText
      default: .any
      }
    }

    var displayName: String {
      switch self {
      case .any: "Any"
      case .cell: "Cell"
      case .button: "Button"
      case .radioButton: "Radio Button"
      case .menuButton: "Menu Button"
      case .popUpButton: "Pop Up Button"
      case .decrementButton: "Decrement Button"
      case .incrementButton: "Increment Button"
      case .staticText: "Static Text"
      }
    }

    var axValue: String {
      switch self {
      case .any: "*"
      case .button: kAXButtonRole
      case .cell: kAXCellRole
      case .radioButton: kAXRadioButtonRole
      case .menuButton: kAXMenuButtonRole
      case .popUpButton: kAXPopUpButtonRole
      case .decrementButton: kAXDecrementButtonAttribute
      case .incrementButton: kAXIncrementButtonAttribute
      case .staticText: kAXStaticTextRole
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

      func run(lhs: String, rhs: String?) -> Bool {
        guard let rhs else { return false }
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

      var displayName: String {
        switch self {
        case .identifier: "Identifier"
        case .description: "Description"
        case .title: "Title"
        case .value: "Value"
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
  }

  var meta: Command.MetaData
  var predicates: [Predicate]

  init(meta: Command.MetaData = .init(), predicates: [Predicate]) {
    self.meta = meta
    self.predicates = predicates
  }
}

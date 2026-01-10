import ApplicationServices

extension UIElementCommand {
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
}

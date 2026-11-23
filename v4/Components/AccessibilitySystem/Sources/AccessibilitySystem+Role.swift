import ApplicationServices

public extension AccessibilitySystem {
  /// An AX role, including values not predefined by this package.
  struct Role: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
      self.rawValue = rawValue
    }

    public static let button = Self(rawValue: kAXButtonRole)
    public static let cell = Self(rawValue: kAXCellRole)
    public static let group = Self(rawValue: kAXGroupRole)
    public static let image = Self(rawValue: kAXImageRole)
    public static let link = Self(rawValue: "AXLink")
    public static let list = Self(rawValue: kAXListRole)
    public static let outline = Self(rawValue: kAXOutlineRole)
    public static let scrollArea = Self(rawValue: kAXScrollAreaRole)
    public static let staticText = Self(rawValue: kAXStaticTextRole)
    public static let table = Self(rawValue: kAXTableRole)
    public static let textField = Self(rawValue: kAXTextFieldRole)
    public static let webArea = Self(rawValue: "AXWebArea")
    public static let window = Self(rawValue: kAXWindowRole)
  }
}

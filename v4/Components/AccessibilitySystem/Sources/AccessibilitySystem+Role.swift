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
    public static let link = Self(rawValue: "AXLink")
    public static let staticText = Self(rawValue: kAXStaticTextRole)
    public static let textField = Self(rawValue: kAXTextFieldRole)
    public static let webArea = Self(rawValue: "AXWebArea")
    public static let window = Self(rawValue: kAXWindowRole)
  }
}

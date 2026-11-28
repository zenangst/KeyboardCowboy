import Carbon

public extension ModifierRemapping {
  enum Modifier: CaseIterable, Sendable {
    case leftCommand, rightCommand
    case leftShift, rightShift
    case leftOption, rightOption
    case leftControl, rightControl

    public var keyCode: UInt16 {
      switch self {
      case .leftCommand: UInt16(kVK_Command)
      case .rightCommand: UInt16(kVK_RightCommand)
      case .leftShift: UInt16(kVK_Shift)
      case .rightShift: UInt16(kVK_RightShift)
      case .leftOption: UInt16(kVK_Option)
      case .rightOption: UInt16(kVK_RightOption)
      case .leftControl: UInt16(kVK_Control)
      case .rightControl: UInt16(kVK_RightControl)
      }
    }
  }

  struct Rule: Equatable, Sendable {
    public let modifier: Modifier
    public let tapKeyCode: UInt16
    public let holdDuration: Duration

    /// Holding preserves the original modifier. The tap target must not be a modifier.
    public init?(modifier: Modifier, tapKeyCode: UInt16, holdDuration: Duration) {
      guard holdDuration > .zero, !Modifier.allCases.contains(where: { $0.keyCode == tapKeyCode }),
            tapKeyCode != UInt16(kVK_CapsLock), tapKeyCode != UInt16(kVK_Function) else { return nil }
      self.modifier = modifier
      self.tapKeyCode = tapKeyCode
      self.holdDuration = holdDuration
    }
  }
}

import Carbon
import CoreGraphics
import IOKit.hidsystem

public extension Keyboard {
  struct Shortcut: Sendable {
    public let key: String
    public let modifiers: [Modifier]

    public init(key: String, modifiers: [Modifier] = []) {
      self.key = key
      self.modifiers = modifiers
    }

    func eventFlags(for code: CGKeyCode) -> CGEventFlags {
      var flags = modifiers.reduce(into: CGEventFlags.maskNonCoalesced) { $0.formUnion($1.flags) }
      // Preserve v3's case-sensitive F-prefix rule, including its device bit.
      if key.hasPrefix("F") {
        flags.formUnion([.maskSecondaryFn, deviceFlag(NX_DEVICELCMDKEYMASK)])
      }
      switch Int(code) {
      case kVK_LeftArrow, kVK_RightArrow, kVK_DownArrow, kVK_UpArrow:
        flags.insert(.maskNumericPad)
      default:
        break
      }
      return flags
    }
  }

  enum Modifier: Sendable {
    case leftShift, rightShift, leftControl, rightControl, leftOption, rightOption, leftCommand, rightCommand
    case function, capsLock

    fileprivate var flags: CGEventFlags {
      switch self {
      case .leftShift: [.maskShift, deviceFlag(NX_DEVICELSHIFTKEYMASK)]
      case .rightShift: [.maskShift, deviceFlag(NX_DEVICERSHIFTKEYMASK)]
      case .leftControl: [.maskControl, deviceFlag(NX_DEVICELCTLKEYMASK)]
      case .rightControl: [.maskControl, deviceFlag(NX_DEVICERCTLKEYMASK)]
      case .leftOption: [.maskAlternate, deviceFlag(NX_DEVICELALTKEYMASK)]
      case .rightOption: [.maskAlternate, deviceFlag(NX_DEVICERALTKEYMASK)]
      case .leftCommand: [.maskCommand, deviceFlag(NX_DEVICELCMDKEYMASK)]
      case .rightCommand: [.maskCommand, deviceFlag(NX_DEVICERCMDKEYMASK)]
      case .function: .maskSecondaryFn
      case .capsLock: .maskAlphaShift
      }
    }
  }
}

private func deviceFlag(_ mask: Int32) -> CGEventFlags {
  CGEventFlags(rawValue: UInt64(mask))
}

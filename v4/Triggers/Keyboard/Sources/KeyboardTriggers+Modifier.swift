import CoreGraphics
import IOKit.hidsystem

public extension KeyboardTriggers {
  enum Modifier: String, Codable, Sendable {
    case function = "fn", capsLock = "⇪"
    case leftShift = "$", rightShift = "r$"
    case leftControl = "^", rightControl = "r^"
    case leftOption = "~", rightOption = "r~"
    case leftCommand = "@", rightCommand = "r@"

    var flags: CGEventFlags {
      func device(_ mask: Int32) -> CGEventFlags { .init(rawValue: UInt64(mask)) }
      switch self {
      case .function: return .maskSecondaryFn
      case .capsLock: return .maskAlphaShift
      case .leftShift: return [.maskShift, device(NX_DEVICELSHIFTKEYMASK)]
      case .rightShift: return [.maskShift, device(NX_DEVICERSHIFTKEYMASK)]
      case .leftControl: return [.maskControl, device(NX_DEVICELCTLKEYMASK)]
      case .rightControl: return [.maskControl, device(NX_DEVICERCTLKEYMASK)]
      case .leftOption: return [.maskAlternate, device(NX_DEVICELALTKEYMASK)]
      case .rightOption: return [.maskAlternate, device(NX_DEVICERALTKEYMASK)]
      case .leftCommand: return [.maskCommand, device(NX_DEVICELCMDKEYMASK)]
      case .rightCommand: return [.maskCommand, device(NX_DEVICERCMDKEYMASK)]
      }
    }
  }
}

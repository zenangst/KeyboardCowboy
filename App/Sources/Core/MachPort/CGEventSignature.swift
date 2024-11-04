import AppKit

struct CGEventSignature: Identifiable, Hashable {
  let id: String

  init (_ keyCode: Int64, _ flags: CGEventFlags) {
    id = "\(keyCode)/0x\(flags.rawValue)"
  }

  static func from(_ cgEvent: CGEvent, keyCode: Int64? = nil) -> Self {
    let keyCode: Int64 = keyCode ?? cgEvent.getIntegerValueField(.keyboardEventKeycode)
    return CGEventSignature(keyCode, cgEvent.flags)
  }
}

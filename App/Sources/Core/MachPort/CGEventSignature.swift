import AppKit

struct CGEventSignature: Identifiable, Hashable {
  let id: String

  init (_ keyCode: Int, _ flags: CGEventFlags) {
    id = "\(keyCode)//0x\(flags.rawValue)"
  }

  static func from(_ cgEvent: CGEvent) -> Self {
    let keyCode: Int64 = cgEvent.getIntegerValueField(.keyboardEventKeycode)
    return CGEventSignature(Int(keyCode), cgEvent.flags)
  }
}

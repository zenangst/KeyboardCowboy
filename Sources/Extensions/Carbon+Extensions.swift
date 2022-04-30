import Carbon.HIToolbox
import Cocoa

extension NSEvent.ModifierFlags {
  var carbon: Int {
    var modifierFlags = 0

    if contains(.control) { modifierFlags |= controlKey }
    if contains(.option) { modifierFlags |= optionKey }
    if contains(.shift) { modifierFlags |= shiftKey }
    if contains(.command) { modifierFlags |= cmdKey }

    return modifierFlags
  }

  init(carbon: Int) {
    self.init()

    if carbon & controlKey == controlKey { insert(.control) }
    if carbon & optionKey == optionKey { insert(.option) }
    if carbon & shiftKey == shiftKey { insert(.shift) }
    if carbon & cmdKey == cmdKey { insert(.command) }
  }
}

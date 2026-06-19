import Cocoa
import CowboyCore

extension NSWorkspace.OpenConfiguration {
  convenience init(_ modifiers: Set<Command.Application.Modifier>) {
    self.init()

    activates = !modifiers.contains(.background)
    hides = modifiers.contains(.hidden)
  }
}

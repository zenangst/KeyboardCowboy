import Foundation
import MachPort

final class PeekApplicationPlugin: @unchecked Sendable {
  @MainActor static var peekEvent: MachPortEvent?

  @MainActor static func set(_ peekEvent: MachPortEvent) {
    Self.peekEvent = peekEvent
  }
}

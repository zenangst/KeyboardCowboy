import CoreGraphics
import Foundation

enum CFRunLoopSourceError: Error {
  case failedToCreateCFRunLoopSource
}

enum CGEventSourceError: Error {
  case failedToCreateCGEventSource
}

extension CFRunLoopSource {
  static func create(with machPort: CFMachPort) throws -> CFRunLoopSource {
    guard let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, machPort, 0) else {
      throw CFRunLoopSourceError.failedToCreateCFRunLoopSource
    }
    return runLoopSource
  }
}

extension CGEventSource {
  static func create(_ stateID: CGEventSourceStateID) throws -> CGEventSource {
    guard let eventSource = CGEventSource(stateID: stateID) else {
      throw CGEventSourceError.failedToCreateCGEventSource
    }
    return eventSource
  }
}

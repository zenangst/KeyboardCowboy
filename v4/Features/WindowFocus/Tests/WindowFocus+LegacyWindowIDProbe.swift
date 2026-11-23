import ApplicationServices
import Darwin

/// Read-only characterization of the private API used by the legacy app.
/// This file belongs only to the test target; the product never loads it.
enum LegacyWindowIDProbe {
  enum Failure: Error {
    case symbolUnavailable
    case ax(operation: String, status: AXError)
    case malformedWindows
    case missingFixture(String)
  }

  struct Reading: Sendable {
    let id: CGWindowID?
    let status: Int32
  }

  private typealias GetWindow = @convention(c) (AXUIElement, UnsafeMutablePointer<CGWindowID>) -> Int32

  static func read(
    pid: pid_t, fixtureTitles: [String]? = nil,
  ) async throws -> [Reading] {
    try await Task.detached {
      // Resolve dynamically so a missing SPI is reported, not a load-time failure.
      guard let process = dlopen(nil, RTLD_LAZY) else { throw Failure.symbolUnavailable }

      defer { dlclose(process) }
      guard let address = dlsym(process, "_AXUIElementGetWindow") else {
        throw Failure.symbolUnavailable
      }

      let getWindow = unsafeBitCast(address, to: GetWindow.self)
      let app = AXUIElementCreateApplication(pid)
      try check(AXUIElementSetMessagingTimeout(app, 1), operation: "setMessagingTimeout")
      var value: CFTypeRef?
      try check(
        AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &value),
        operation: kAXWindowsAttribute,
      )
      guard let windows = value as? [AXUIElement] else { throw Failure.malformedWindows }

      let ordered: [AXUIElement] = if let fixtureTitles {
        // Only the owned fixtures are labeled by title; the bridge does not use titles.
        try fixtureTitles.map { label in
          let window = windows.first { window in
            var title: CFTypeRef?
            return AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &title) == .success
              && (title as? String) == label
          }
          guard let window else { throw Failure.missingFixture(label) }

          return window
        }
      } else {
        windows
      }

      return ordered.map { window in
        var id = kCGNullWindowID
        let status = getWindow(window, &id)
        return Reading(id: status == AXError.success.rawValue && id != kCGNullWindowID ? id : nil, status: status)
      }
    }
    .value
  }

  private static func check(_ status: AXError, operation: String) throws {
    guard status == .success else { throw Failure.ax(operation: operation, status: status) }
  }
}

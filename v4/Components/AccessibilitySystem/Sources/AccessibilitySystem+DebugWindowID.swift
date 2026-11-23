#if DEBUG || WINDOW_FOCUS_VALIDATION
import ApplicationServices
import Darwin

extension AccessibilitySystem {
  enum DebugWindowID {
    private typealias GetWindow = @convention(c) (AXUIElement, UnsafeMutablePointer<CGWindowID>) -> Int32

    // Keep the function pointer scoped to the open handle and this call.
    static func withLookup<Result>(_ operation: ((AXUIElement) -> CGWindowID?) throws -> Result) rethrows -> Result? {
      guard let process = dlopen(nil, RTLD_LAZY) else { return nil }
      defer { dlclose(process) }
      guard let address = dlsym(process, "_AXUIElementGetWindow") else { return nil }

      let getWindow = unsafeBitCast(address, to: GetWindow.self)
      return try operation { element in
        var id = kCGNullWindowID
        let status = getWindow(element, &id)
        return status == AXError.success.rawValue && id != kCGNullWindowID ? id : nil
      }
    }
  }
}
#endif

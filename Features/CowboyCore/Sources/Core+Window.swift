import CoreGraphics

public extension Core {
  struct CGWindow: Identifiable, Hashable {
    public let id: Int
    public let ownerName: String
    public let pid: pid_t
    public let rect: CGRect
    public let windowName: String

    init?(_ dictionary: [String: Any]) {
      guard let pid = dictionary[kCGWindowOwnerPID, pid_t.self] else { return nil }
      guard let id = dictionary[kCGWindowNumber, Int.self] else { return nil }

      self.id = id
      self.pid = pid
      self.windowName = dictionary[kCGWindowName, ""]
      self.ownerName = dictionary[kCGWindowOwnerName, ""]
      self.rect = Rect(dictionary[kCGWindowBounds, [String: Double]()]).toCGRect
    }
  }
}

private extension Dictionary<String, Any> {
  subscript<T>(key: CFString, type: T.Type) -> T? {
    self[key as String] as? T
  }

  subscript<T>(key: CFString, default: T) -> T {
    (self[key as String] as? T) ?? `default`
  }
}

private struct Rect: Hashable {
  let x: Double
  let y: Double
  let width: Double
  let height: Double

  var toCGRect: CGRect {
    CGRect(x: x, y: y, width: width, height: height)
  }

  init(_ dictionary: [String: Double]) {
    self.x = dictionary["X", default: 0.0]
    self.y = dictionary["Y", default: 0.0]
    self.width = dictionary["Width", default: 0.0]
    self.height = dictionary["Height", default: 0.0]
  }

  init(_ rect: CGRect) {
    self.x = rect.origin.x
    self.y = rect.origin.y
    self.width = rect.size.width
    self.height = rect.size.height
  }
}

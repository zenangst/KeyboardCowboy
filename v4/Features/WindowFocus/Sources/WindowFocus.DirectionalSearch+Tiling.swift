public extension WindowFocus.DirectionalSearch {
  enum Tiling: Sendable {
    case left, right, top, bottom
    case topLeft, topRight, bottomLeft, bottomRight

    func reroute(_ direction: Direction) -> Direction {
      switch (self, direction) {
      case (.left, .up), (.left, .down), (.topLeft, .down), (.bottomLeft, .up): .right
      case (.right, .up), (.right, .down), (.bottom, .up), (.bottom, .down),
           (.topRight, .down), (.bottomRight, .up): .left
      case (.left, .right), (.right, .left), (.bottom, .left), (.topLeft, .right), (.topRight, .left): .down
      case (.right, .right), (.bottom, .right), (.bottomLeft, .right), (.bottomRight, .left): .up
      default: direction
      }
    }
  }
}

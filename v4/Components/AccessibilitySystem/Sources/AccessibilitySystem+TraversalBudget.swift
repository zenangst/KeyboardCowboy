public extension AccessibilitySystem {
  struct TraversalBudget: Sendable {
    public var maximumNodes: Int
    public var maximumDepth: Int
    public var elapsedLimit: Duration

    public init(maximumNodes: Int = 1000, maximumDepth: Int = 64,
                elapsedLimit: Duration = .seconds(2)) {
      self.maximumNodes = maximumNodes
      self.maximumDepth = maximumDepth
      self.elapsedLimit = elapsedLimit
    }
  }
}

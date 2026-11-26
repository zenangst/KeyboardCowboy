public extension UserSpace.Snapshot {
  struct Apps: Sendable {
    public let frontMost: UserSpace.Application?
    public let previous: UserSpace.Application?

    public init(frontMost: UserSpace.Application? = nil, previous: UserSpace.Application? = nil) {
      self.frontMost = frontMost
      self.previous = previous
    }
  }
}

public extension KeyboardTriggers {
  struct CompiledSequence: Sendable {
    public let signature: Signature
    public let continuation: [Signature]
    public let endsWithAnyKey: Bool
  }
}

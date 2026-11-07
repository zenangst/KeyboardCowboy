struct SpacingSpec: Sendable, Hashable {
  let none: Double
  let extraLarge: Double
  let large: Double
  let medium: Double
  let small: Double

  init(extraLarge: Double, large: Double, medium: Double, small: Double) {
    self.none = 0
    self.extraLarge = extraLarge
    self.large = large
    self.medium = medium
    self.small = small
  }
}

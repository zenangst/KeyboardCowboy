infix operator <-

public func <- <T: Equatable>(lhs: inout T, rhs: T) {
  guard lhs != rhs else { return }

  lhs = rhs
}

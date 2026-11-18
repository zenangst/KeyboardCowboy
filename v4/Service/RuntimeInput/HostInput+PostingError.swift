extension HostInput {
  enum PostingError: Error, Equatable {
    case invalidKeyCode(Int)
  }
}

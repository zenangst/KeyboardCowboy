extension KeyboardCommand {
  enum Kind: Codable, Hashable {
    case key(command: KeyCommand)
    case inputSource(command: InputSourceCommand)
  }
}

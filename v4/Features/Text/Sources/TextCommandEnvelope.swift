/// The persisted text-command envelope. Input is not interpolated during decoding.
public struct TextCommandEnvelope: Codable, Sendable, Equatable {
  public var textCommand: TextCommand

  public init(textCommand: TextCommand) {
    self.textCommand = textCommand
  }
}

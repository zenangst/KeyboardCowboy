extension TextCommand {
  struct TypeCommand: MetaDataProviding {
    enum Mode: String, Hashable, Codable, CaseIterable, Identifiable {
      var id: String { rawValue }
      case typing = "Typing"
      case instant = "Instant"

      var symbol: String {
        switch self {
        case .typing: "keyboard"
        case .instant: "bolt.fill"
        }
      }
    }

    enum Action: String, Hashable, Codable, CaseIterable {
      case insertEnter

      var displayValue: String {
        switch self {
        case .insertEnter: "Press Enter automatically after typing."
        }
      }
    }

    var input: String
    var mode: Mode = .instant
    var meta: Command.MetaData
    var actions: Set<Action>

    init(_ input: String, mode: Mode, meta: Command.MetaData = .init(), actions: Set<Action>) {
      self.input = input
      self.mode = mode
      self.meta = meta
      self.actions = actions
    }

    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.input = try container.decode(String.self, forKey: .input)
      self.mode = try container.decodeIfPresent(Mode.self, forKey: .mode) ?? .instant
      self.meta = try container.decode(Command.MetaData.self, forKey: .meta)
      self.actions = try container.decodeIfPresent(Set<TypeCommand.Action>.self, forKey: .actions) ?? []
    }

    enum CodingKeys: CodingKey {
      case input
      case mode
      case meta
      case actions
    }

    func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: TextCommand.TypeCommand.CodingKeys.self)
      try container.encode(self.input, forKey: TextCommand.TypeCommand.CodingKeys.input)
      try container.encode(self.mode, forKey: TextCommand.TypeCommand.CodingKeys.mode)
      try container.encode(self.meta, forKey: TextCommand.TypeCommand.CodingKeys.meta)

      let sortedActions = self.actions.sorted(by: { $0.rawValue < $1.rawValue  })
      try container.encode(sortedActions, forKey: TextCommand.TypeCommand.CodingKeys.actions)
    }

    func copy() -> TypeCommand {
      TypeCommand(input, mode: mode, meta: meta.copy(), actions: actions)
    }
  }
}

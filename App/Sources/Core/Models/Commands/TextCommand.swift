import Foundation

struct TextCommand: MetaDataProviding {
  enum Kind: Codable, Hashable {
    case setFindTo(SetFindToCommand)
    case insertText(TypeCommand)
  }

  var meta: Command.MetaData {
    get {
      switch kind {
      case .insertText(let command): command.meta
      case .setFindTo(let command): command.meta
      }
    }
    set {
      switch kind {
      case .insertText(let command):
        self = TextCommand(.insertText(TypeCommand(command.input, mode: command.mode, meta: newValue)))
      case .setFindTo(let command):
        self = TextCommand(.setFindTo(SetFindToCommand(input: command.input, meta: newValue)))
      }
    }
  }

  var kind: Kind

  init(_ kind: Kind) {
    self.kind = kind
  }

  struct SetFindToCommand: MetaDataProviding {
    let input: String
    var meta: Command.MetaData
  }

  struct TypeCommand: MetaDataProviding {
    enum Mode: String, Hashable, Codable, CaseIterable, Identifiable {
      var id: String { rawValue }
      case typing = "Typing"
      case instant = "Instant"
    }

    var input: String
    var mode: Mode = .instant
    var meta: Command.MetaData

    init(_ input: String, mode: Mode, meta: Command.MetaData = .init()) {
      self.input = input
      self.mode = mode
      self.meta = meta
    }

    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.input = try container.decode(String.self, forKey: .input)
      self.mode = try container.decodeIfPresent(Mode.self, forKey: .mode) ?? .instant

      do {
        self.meta = try container.decode(Command.MetaData.self, forKey: .meta)
      } catch {
        self.meta = try MetaDataMigrator.migrate(decoder)
      }
    }
  }
}

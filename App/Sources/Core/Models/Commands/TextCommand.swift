import Foundation

struct TextCommand: MetaDataProviding {
  enum Kind: Codable, Hashable {
    case insertText(TypeCommand)

    func copy() -> Self {
      switch self {
      case .insertText(let command): .insertText(command.copy())
      }
    }
  }

  var meta: Command.MetaData {
    get {
      switch kind {
      case .insertText(let command): command.meta
      }
    }
    set {
      switch kind {
      case .insertText(let command):
        self = TextCommand(.insertText(TypeCommand(command.input, mode: command.mode, meta: newValue)))
      }
    }
  }

  var kind: Kind

  init(_ kind: Kind) {
    self.kind = kind
  }

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

    func copy() -> TypeCommand {
      TypeCommand(input, mode: mode, meta: meta.copy())
    }
  }

  func copy() -> TextCommand {
    TextCommand(kind.copy())
  }
}

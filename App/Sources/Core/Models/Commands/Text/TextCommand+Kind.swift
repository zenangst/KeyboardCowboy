//
//  TextCommand+Kind.swift
//  Keyboard Cowboy
//
//  Created by Christoffer Winterkvist on 3/5/25.
//

extension TextCommand {
  enum Kind: Codable, Hashable {
    case insertText(TypeCommand)

    func copy() -> Self {
      switch self {
      case let .insertText(command): .insertText(command.copy())
      }
    }
  }

  var meta: Command.MetaData {
    get {
      switch kind {
      case let .insertText(command): command.meta
      }
    }
    set {
      switch kind {
      case let .insertText(command):
        self = TextCommand(.insertText(TypeCommand(command.input, mode: command.mode, meta: newValue, actions: command.actions)))
      }
    }
  }
}

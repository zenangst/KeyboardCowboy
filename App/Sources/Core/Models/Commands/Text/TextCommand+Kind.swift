//
//  Kind.swift
//  Keyboard Cowboy
//
//  Created by Christoffer Winterkvist on 3/5/25.
//

extension TextCommand {
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
        self = TextCommand(.insertText(TypeCommand(command.input, mode: command.mode, meta: newValue, actions: command.actions)))
      }
    }
  }
}

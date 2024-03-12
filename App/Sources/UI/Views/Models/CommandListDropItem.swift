import CoreTransferable
import Foundation

enum CommandListDropItem: Transferable, Equatable {
  case command(CommandViewModel)
  case url(URL)

  static var transferRepresentation: some TransferRepresentation {
    ProxyRepresentation { CommandListDropItem.command($0) }
    ProxyRepresentation { CommandListDropItem.url($0) }
  }
}

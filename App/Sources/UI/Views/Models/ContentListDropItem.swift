import CoreTransferable
import Foundation

enum ContentListDropItem: Codable, Transferable, Equatable {
  case workflow(GroupDetailViewModel)
  case command(CommandViewModel)

  static var transferRepresentation: some TransferRepresentation {
    ProxyRepresentation { ContentListDropItem.workflow($0) }
    ProxyRepresentation { ContentListDropItem.command($0) }
  }
}

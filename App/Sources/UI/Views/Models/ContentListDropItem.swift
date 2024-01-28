import CoreTransferable
import Foundation

enum ContentListDropItem: Codable, Transferable {
  case workflow(ContentViewModel)
  case command(CommandViewModel)

  static var transferRepresentation: some TransferRepresentation {
    ProxyRepresentation { ContentListDropItem.workflow($0) }
    ProxyRepresentation { ContentListDropItem.command($0) }
  }
}

import CoreTransferable
import Foundation

enum SidebarListDropItem: Codable, Transferable, Equatable {
  case workflow(ContentViewModel)
  case group(GroupViewModel)

  static var transferRepresentation: some TransferRepresentation {
    ProxyRepresentation { SidebarListDropItem.workflow($0) }
    ProxyRepresentation { SidebarListDropItem.group($0) }
  }
}

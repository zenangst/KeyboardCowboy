import CoreTransferable
import Foundation

enum SidebarListDropItem: Codable, Transferable, Equatable {
  case workflow(GroupDetailViewModel)
  case group(GroupViewModel)

  static var transferRepresentation: some TransferRepresentation {
    ProxyRepresentation { SidebarListDropItem.workflow($0) }
    ProxyRepresentation { SidebarListDropItem.group($0) }
  }
}

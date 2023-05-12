/*
 Credit: https://stackoverflow.com/a/74320523
 */

import CoreTransferable

enum DropItem: Codable, Transferable {
  case none
  case text(String)
  case url(URL)

  static var transferRepresentation: some TransferRepresentation {
    ProxyRepresentation { DropItem.text($0) }
    ProxyRepresentation { DropItem.url($0) }
  }

  var text: String? {
    switch self {
    case .text(let str): return str
    default: return nil
    }
  }

  var url: URL? {
    switch self {
    case.url(let url): return url
    default: return nil
    }
  }
}

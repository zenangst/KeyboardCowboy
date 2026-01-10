import Bonzai
import SwiftUI

struct GroupViewModel: Identifiable, Hashable, Codable, Sendable, Transferable {
  static var transferRepresentation: some TransferRepresentation {
    CodableRepresentation(contentType: .group)
  }

  let id: String
  let name: String
  let icon: Icon?
  let color: String
  let symbol: String
  let bundleIdentifiers: [String]
  let userModes: [UserMode]
  let count: Int
  var isDisabled: Bool
  var isEnabled: Bool { !isDisabled }

  init(id: String, name: String, icon: Icon?, color: String, symbol: String, bundleIdentifiers: [String], userModes: [UserMode],
       count: Int, isDisabled: Bool = false) {
    self.id = id
    self.name = name
    self.icon = icon
    self.color = color
    self.symbol = symbol
    self.userModes = userModes
    self.bundleIdentifiers = bundleIdentifiers
    self.count = count
    self.isDisabled = isDisabled
  }
}

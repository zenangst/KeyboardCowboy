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
  let userModes: [UserMode]
  let count: Int

}

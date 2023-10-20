import Bonzai
import SwiftUI
import UniformTypeIdentifiers

struct GroupViewModel: Identifiable, Hashable, Codable, Sendable, Transferable {
  let id: String
  let name: String
  let icon: Icon?
  let color: String
  let symbol: String
  let count: Int

  static var transferRepresentation: some TransferRepresentation {
    CodableRepresentation(contentType: .workflowGroup)
  }
}

extension UTType {
  static var workflowGroup: UTType {
    UTType(exportedAs: "com.zenangst.Keyboard-Cowboy.WorkflowGroup", conformingTo: .data)
  }
}

import Foundation

extension Identifiable {
  func draggablePayload(prefix: String, selections: Set<Self.ID>) -> String where Self.ID == String {
    var payload = prefix

    if selections.contains(self.id) {
      payload += selections.joined(separator: ",")
    } else {
      payload += self.id
    }

    return payload

  }
}

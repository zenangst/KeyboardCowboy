import Foundation

struct UserMode: Identifiable, Codable, Hashable, Sendable {
  var id: String
  var name: String
  var isEnabled: Bool
}

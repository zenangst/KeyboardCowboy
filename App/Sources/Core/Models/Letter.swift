import Foundation

struct Letter: Identifiable, Hashable {
  let id: String = UUID().uuidString
  let string: String
}

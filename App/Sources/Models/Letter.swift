import Foundation

struct Letter: Identifiable {
  let id: String = UUID().uuidString
  let string: String
}

import Foundation

struct ConfigurationViewModel: Hashable, Identifiable {
  let id: String = UUID().uuidString
  let name: String = UUID().uuidString
  let selected: Bool = false
}

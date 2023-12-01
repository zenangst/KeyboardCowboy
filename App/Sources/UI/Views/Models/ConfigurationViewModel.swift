import Foundation

struct ConfigurationViewModel: Hashable, Identifiable {
  let id: String
  let name: String
  let selected: Bool
  let userModes: [UserMode]

  init(id: String, name: String, selected: Bool, userModes: [UserMode] = []) {
    self.id = id
    self.name = name
    self.selected = selected
    self.userModes = userModes
  }
}

import SwiftUI

struct ContentViewModel: Identifiable, Hashable {
  let id: String
  let groupName: String?
  let name: String
  let images: [ImageModel]
  let binding: String?
  let badge: Int
  let badgeOpacity: Double
  let isEnabled: Bool

  internal init(id: String, groupName: String? = nil, name: String, images: [ContentViewModel.ImageModel], binding: String? = nil, badge: Int, badgeOpacity: Double, isEnabled: Bool) {
    self.id = id
    self.groupName = groupName
    self.name = name
    self.images = images
    self.binding = binding
    self.badge = badge
    self.badgeOpacity = badgeOpacity
    self.isEnabled = isEnabled
  }

  struct ImageModel: Identifiable, Hashable {
    let id: String
    let offset: Double
    let kind: Kind

    enum Kind: Hashable {
      case command(DetailViewModel.CommandViewModel.Kind)
      case icon(path: String)
    }
  }
}

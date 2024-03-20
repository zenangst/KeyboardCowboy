import Bonzai
import SwiftUI

struct ContentViewModel: Identifiable, Hashable, Codable,
                         Sendable, Transferable {
  static var transferRepresentation: some TransferRepresentation {
    CodableRepresentation(contentType: .workflow)
  }

  enum Trigger: Hashable, Codable {
    case application(String)
    case keyboard(String)
    case snippet(String)
  }

  let id: String
  let groupName: String?
  let name: String
  let images: [ImageModel]
  let overlayImages: [ImageModel]
  let trigger: Trigger?
  let badge: Int
  let badgeOpacity: Double
  let isEnabled: Bool

  internal init(id: String, groupName: String? = nil, name: String,
                images: [ContentViewModel.ImageModel],
                overlayImages: [ContentViewModel.ImageModel],
                trigger: Trigger? = nil,
                badge: Int,
                badgeOpacity: Double, isEnabled: Bool) {
    self.id = id
    self.groupName = groupName
    self.name = name
    self.images = images
    self.overlayImages = overlayImages
    self.badge = badge
    self.badgeOpacity = badgeOpacity
    self.trigger = trigger
    self.isEnabled = isEnabled
  }

  struct ImageModel: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let offset: Double
    let kind: Kind

    enum Kind: Hashable, Codable, Sendable {
      case command(CommandViewModel.Kind)
      case icon(Icon)
    }
  }
}

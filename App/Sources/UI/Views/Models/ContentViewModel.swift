import Bonzai
import SwiftUI
import UniformTypeIdentifiers

struct ContentViewModel: Identifiable, Hashable, Codable,
                          Sendable, Transferable {
  let id: String
  let groupName: String?
  let name: String
  let images: [ImageModel]
  let overlayImages: [ImageModel]
  let binding: String?
  let badge: Int
  let badgeOpacity: Double
  let isEnabled: Bool

  internal init(id: String, groupName: String? = nil, name: String,
                images: [ContentViewModel.ImageModel],
                overlayImages: [ContentViewModel.ImageModel],
                binding: String? = nil, badge: Int,
                badgeOpacity: Double, isEnabled: Bool) {
    self.id = id
    self.groupName = groupName
    self.name = name
    self.images = images
    self.overlayImages = overlayImages
    self.binding = binding
    self.badge = badge
    self.badgeOpacity = badgeOpacity
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

  static var transferRepresentation: some TransferRepresentation {
    CodableRepresentation(contentType: .workflow)
  }
}

extension UTType {
  static var workflow: UTType {
    UTType(exportedAs: "com.zenangst.Keyboard-Cowboy.Workflow", conformingTo: .data)
  }
}

import SwiftUI

struct ContentViewModel: Identifiable, Hashable {
  let id: String
  let name: String
  let images: [ImageModel]
  let binding: String?
  let badge: Int
  let badgeOpacity: Double
  let isEnabled: Bool

  struct ImageModel: Identifiable, Hashable {
    let id: String
    let offset: Double
    let kind: Kind

    enum Kind: Hashable {
      case command(DetailViewModel.CommandViewModel.Kind)
      case nsImage(NSImage)
    }
  }
}

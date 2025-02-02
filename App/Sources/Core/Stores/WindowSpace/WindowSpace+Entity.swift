import Foundation

extension WindowSpace {
  struct Entity: Identifiable {
    enum Kind: Equatable {
      case standard
      case dialog
      case unknown
    }

    let id: Int
    let bundleIdentifier: String

    var kind: Kind = .unknown
    var properties: Properties?

    struct Properties {
      var title: String?
      var identifier: String?
    }
  }
}

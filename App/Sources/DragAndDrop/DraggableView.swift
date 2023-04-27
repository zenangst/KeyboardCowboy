import Foundation
import UniformTypeIdentifiers
import SwiftUI

enum DraggableView: Identifiable, Hashable, Codable, Sendable, Transferable {
  var id: String {
    switch self {
    case .group(let models):
      return models.map(\.id).joined()
    case .workflow(let models):
      return models.map(\.id).joined()
    }
  }

  case group([GroupViewModel])
  case workflow([ContentViewModel])
  static var transferRepresentation: some TransferRepresentation {
    CodableRepresentation(contentType: .draggableView)
  }
}

extension UTType {
  static var draggableView: UTType {
    UTType(exportedAs: "com.zenangst.Keyboard-Cowboy.DraggableView")
  }
}


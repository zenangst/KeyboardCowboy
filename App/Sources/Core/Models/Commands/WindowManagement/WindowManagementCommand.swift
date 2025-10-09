import Foundation
import SwiftUI

struct WindowManagementCommand: MetaDataProviding {
  enum Mode: String, Identifiable, Codable, Hashable, CaseIterable {
    var id: String { rawValue }
    case center
    case relative

    var displayValue: String {
      switch self {
      case .center:
        "Center"
      case .relative:
        "Relative"
      }
    }
  }

  var kind: Kind
  var animationDuration: Double
  var meta: Command.MetaData

  enum CodingKeys: CodingKey {
    case kind
    case animationDuration
    case meta
  }

  init(id: String = UUID().uuidString, name: String,
       kind: Kind,
       notification: Command.Notification? = nil,
       animationDuration: Double)
  {
    self.kind = kind
    meta = Command.MetaData(id: id, name: name, isEnabled: true, notification: notification)
    self.animationDuration = animationDuration
  }

  init(kind: Kind, meta: Command.MetaData, animationDuration: Double) {
    self.kind = kind
    self.meta = meta
    self.animationDuration = animationDuration
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    kind = try container.decode(Kind.self, forKey: .kind)
    animationDuration = try container.decodeIfPresent(Double.self, forKey: .animationDuration) ?? 0
    meta = try container.decode(Command.MetaData.self, forKey: .meta)
  }

  func copy() -> WindowManagementCommand {
    WindowManagementCommand(kind: kind, meta: meta.copy(), animationDuration: animationDuration)
  }
}

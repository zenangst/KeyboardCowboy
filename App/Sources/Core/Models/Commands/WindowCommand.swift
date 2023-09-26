import Foundation
import SwiftUI

struct WindowCommand: MetaDataProviding {
  enum Direction: String, Identifiable, Codable, CaseIterable {
    var id: String { rawValue }

    case topLeading
    case top
    case topTrailing
    case leading
    case trailing
    case bottomLeading
    case bottom
    case bottomTrailing

    func imageSystemName(increment: Bool) -> String {
      switch self {
      case .leading:
        return increment ? "arrow.left" : "arrow.right"
      case .topLeading:
        return increment ? "arrow.up.left" : "arrow.down.right"
      case .top:
        return increment ? "arrow.up" : "arrow.down"
      case .topTrailing:
        return increment ? "arrow.up.right" : "arrow.down.left"
      case .trailing:
        return increment ? "arrow.right" : "arrow.left"
      case .bottomTrailing:
        return increment ? "arrow.down.right" : "arrow.up.left"
      case .bottom:
        return increment ? "arrow.down" : "arrow.up"
      case .bottomLeading:
        return increment ? "arrow.down.left" : "arrow.up.right"
      }
    }

    func displayValue(increment: Bool) -> String {
      switch self {
      case .leading:
        return increment ? "←" : "→"
      case .topLeading:
        return increment ? "↖" : "↘"
      case .top:
        return increment ? "↑" : "↓"
      case .topTrailing:
        return increment ? "↗" : "↙"
      case .trailing:
        return increment ? "→" : "←"
      case .bottomTrailing:
        return increment ? "↘" : "↖"
      case .bottom:
        return increment ? "↓" : "↑"
      case .bottomLeading:
        return increment ? "↙" : "↗"
      }
    }
  }

  enum Kind: Identifiable, Hashable, Codable {
    var id: String {
      switch self {
      case .fullscreen:
        return "fullscreen"
      case .center:
        return "center"
      case .decreaseSize(let byValue, let direction, _):
        return "decreaseSize:\(byValue)\(direction.rawValue)"
      case .increaseSize(let byValue, let direction, _):
        return "increaseSize:\(byValue)\(direction.rawValue)"
      case .move(let toValue, let direction, _):
        return "move:\(toValue)\(direction.rawValue)"
      case .moveToNextDisplay(let mode):
        return "moveToNextDisplay.\(mode.rawValue)"
      case .anchor:
        return "anchor"
      }
    }

    case increaseSize(by: Int, direction: Direction, constrainedToScreen: Bool)
    case decreaseSize(by: Int, direction: Direction, constrainedToScreen: Bool)
    case move(by: Int, direction: Direction, constrainedToScreen: Bool)
    case fullscreen(padding: Int)
    case center
    case moveToNextDisplay(mode: Mode)
    case anchor(position: Direction, padding: Int)

    var displayValue: String {
      switch self {
      case .center:
        return "Center Window"
      case .fullscreen:
        return "Fullscreen"
      case .move:
        return "Move Window"
      case .decreaseSize:
        return "Shrink Window"
      case .increaseSize:
        return "Grow Window"
      case .moveToNextDisplay(let mode):
        return "Move to Next Display - \(mode.displayValue)"
      case .anchor:
        return "Anchor and Resize Window"
      }
    }

    static var allCases: [Kind] {
      [.center,
       .fullscreen(padding: 0),
       .move(by: 0, direction: .trailing, constrainedToScreen: false),
       .decreaseSize(by: 0, direction: .bottomTrailing, constrainedToScreen: false),
       .increaseSize(by: 0, direction: .bottomTrailing, constrainedToScreen: false),
       .moveToNextDisplay(mode: .center),
       .moveToNextDisplay(mode: .relative),
       .anchor(position: .leading, padding: 0)
      ]
    }

    var isIncremental: Bool {
      switch self {
      case .decreaseSize:
        return false
      default:
        return true
      }
    }
  }

  enum Mode: String, Identifiable, Codable, Hashable, CaseIterable {
    var id: String { rawValue }
    case center
    case relative

    var displayValue: String {
      switch self {
      case .center:
        return "Center"
      case .relative:
        return "Relative"
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
       kind: Kind, notification: Bool, animationDuration: Double) {
    self.kind = kind
    self.meta = Command.MetaData(id: id, name: name, isEnabled: true, notification: notification)
    self.animationDuration = animationDuration
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.kind = try container.decode(Kind.self, forKey: .kind)
    self.animationDuration = try container.decodeIfPresent(Double.self, forKey: .animationDuration) ?? 0
    self.meta = try container.decode(Command.MetaData.self, forKey: .meta)
  }
}

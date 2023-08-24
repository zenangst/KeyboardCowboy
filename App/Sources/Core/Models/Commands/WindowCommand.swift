import Foundation
import SwiftUI

struct WindowCommand: MetaDataProviding {
  enum Direction: String, Identifiable, Codable {
    var id: String { rawValue }

    case leading
    case topLeading
    case top
    case topTrailing
    case trailing
    case bottomTrailing
    case bottom
    case bottomLeading

    var displayValue: String {
      switch self {
      case .leading:
        return "←"
      case .topLeading:
        return "↖"
      case .top:
        return "↑"
      case .topTrailing:
        return "↗"
      case .trailing:
        return "→"
      case .bottomTrailing:
        return "↘"
      case .bottom:
        return "↓"
      case .bottomLeading:
        return "↙"
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
      }
    }

    case increaseSize(by: Int, direction: Direction, constrainedToScreen: Bool)
    case decreaseSize(by: Int, direction: Direction, constrainedToScreen: Bool)
    case move(by: Int, direction: Direction, constrainedToScreen: Bool)
    case fullscreen(padding: Int)
    case center
    case moveToNextDisplay(mode: Mode)

    var displayValue: String {
      switch self {
      case .center:
        return "Center Window"
      case .fullscreen:
        return "Fullscreen"
      case .move:
        return "Move window"
      case .decreaseSize:
        return "Shrink window"
      case .increaseSize:
        return "Grow window"
      case .moveToNextDisplay(let mode):
        return "Move to Next Display - \(mode.displayValue)"
      }
    }

    static var allCases: [Kind] {
      [.center,
       .fullscreen(padding: 0),
       .move(by: 0, direction: .trailing, constrainedToScreen: false),
       .decreaseSize(by: 0, direction: .trailing, constrainedToScreen: false),
       .increaseSize(by: 0, direction: .trailing, constrainedToScreen: false),
       .moveToNextDisplay(mode: .center),
       .moveToNextDisplay(mode: .relative)]
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
  var meta: Command.MetaData

  init(id: String = UUID().uuidString, name: String, kind: Kind, notification: Bool) {
    self.kind = kind
    self.meta = Command.MetaData(id: id, name: name, isEnabled: true, notification: notification)
  }
}

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
      case .increaseSize(let byValue, let direction, let padding, _):
        return "increaseSize:\(byValue)\(direction.rawValue):\(padding)"
      case .move(let toValue, let direction, let padding , _):
        return "move:\(toValue)\(direction.rawValue):\(padding)"
      case .moveToNextDisplay(let mode):
        return "moveToNextDisplay.\(mode.rawValue)"
      case .anchor:
        return "anchor"
      }
    }

    case increaseSize(by: Int, direction: Direction, padding: Int, constrainedToScreen: Bool)
    case decreaseSize(by: Int, direction: Direction, constrainedToScreen: Bool)
    case move(by: Int, direction: Direction, padding: Int, constrainedToScreen: Bool)
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
       .move(by: 0, direction: .trailing, padding: 0, constrainedToScreen: false),
       .decreaseSize(by: 0, direction: .bottomTrailing, constrainedToScreen: false),
       .increaseSize(by: 0, direction: .bottomTrailing, padding: 0, constrainedToScreen: false),
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

    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: WindowCommand.Kind.CodingKeys.self)
      var allKeys = ArraySlice(container.allKeys)
      guard let onlyKey = allKeys.popFirst(), allKeys.isEmpty else {
        throw DecodingError.typeMismatch(WindowCommand.Kind.self, DecodingError.Context.init(codingPath: container.codingPath, debugDescription: "Invalid number of keys found, expected one.", underlyingError: nil))
      }
      switch onlyKey {
      case .increaseSize:
        let nestedContainer = try container.nestedContainer(keyedBy: WindowCommand.Kind.IncreaseSizeCodingKeys.self, forKey: WindowCommand.Kind.CodingKeys.increaseSize)
        self = WindowCommand.Kind.increaseSize(
          by: try nestedContainer.decode(Int.self, forKey: WindowCommand.Kind.IncreaseSizeCodingKeys.by),
          direction: try nestedContainer.decode(WindowCommand.Direction.self, forKey: WindowCommand.Kind.IncreaseSizeCodingKeys.direction),
          padding: try nestedContainer.decodeIfPresent(Int.self, forKey: WindowCommand.Kind.IncreaseSizeCodingKeys.padding) ?? 0,
          constrainedToScreen: try nestedContainer.decode(Bool.self, forKey: WindowCommand.Kind.IncreaseSizeCodingKeys.constrainedToScreen)
        )
      case .decreaseSize:
        let nestedContainer = try container.nestedContainer(keyedBy: WindowCommand.Kind.DecreaseSizeCodingKeys.self, forKey: WindowCommand.Kind.CodingKeys.decreaseSize)
        self = WindowCommand.Kind.decreaseSize(
          by: try nestedContainer.decode(Int.self, forKey: WindowCommand.Kind.DecreaseSizeCodingKeys.by),
          direction: try nestedContainer.decode(WindowCommand.Direction.self, forKey: WindowCommand.Kind.DecreaseSizeCodingKeys.direction),
          constrainedToScreen: try nestedContainer.decode(Bool.self, forKey: WindowCommand.Kind.DecreaseSizeCodingKeys.constrainedToScreen)
        )
      case .move:
        let nestedContainer = try container.nestedContainer(keyedBy: WindowCommand.Kind.MoveCodingKeys.self, forKey: WindowCommand.Kind.CodingKeys.move)
        self = WindowCommand.Kind.move(
          by: try nestedContainer.decode(Int.self, forKey: WindowCommand.Kind.MoveCodingKeys.by),
          direction: try nestedContainer.decode(WindowCommand.Direction.self, forKey: WindowCommand.Kind.MoveCodingKeys.direction),
          padding: try nestedContainer.decodeIfPresent(Int.self, forKey: WindowCommand.Kind.MoveCodingKeys.padding) ?? 0,
          constrainedToScreen: try nestedContainer.decode(Bool.self, forKey: WindowCommand.Kind.MoveCodingKeys.constrainedToScreen)
        )
      case .fullscreen:
        let nestedContainer = try container.nestedContainer(keyedBy: WindowCommand.Kind.FullscreenCodingKeys.self, forKey: WindowCommand.Kind.CodingKeys.fullscreen)
        self = WindowCommand.Kind.fullscreen(
          padding: try nestedContainer.decode(Int.self, forKey: WindowCommand.Kind.FullscreenCodingKeys.padding)
        )
      case .center:
        self = WindowCommand.Kind.center
      case .moveToNextDisplay:
        let nestedContainer = try container.nestedContainer(
          keyedBy: WindowCommand.Kind.MoveToNextDisplayCodingKeys.self,
          forKey: WindowCommand.Kind.CodingKeys.moveToNextDisplay
        )
        self = WindowCommand.Kind.moveToNextDisplay(mode: try nestedContainer.decode(WindowCommand.Mode.self, forKey: WindowCommand.Kind.MoveToNextDisplayCodingKeys.mode))
      case .anchor:
        let nestedContainer = try container.nestedContainer(keyedBy: WindowCommand.Kind.AnchorCodingKeys.self, forKey: WindowCommand.Kind.CodingKeys.anchor)
        self = WindowCommand.Kind.anchor(
          position: try nestedContainer.decode(WindowCommand.Direction.self, forKey: WindowCommand.Kind.AnchorCodingKeys.position),
          padding: try nestedContainer.decode(Int.self, forKey: WindowCommand.Kind.AnchorCodingKeys.padding)
        )
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

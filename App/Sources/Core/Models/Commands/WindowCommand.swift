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
      case .leading: increment ? "arrow.left" : "arrow.right"
      case .topLeading: increment ? "arrow.up.left" : "arrow.down.right"
      case .top: increment ? "arrow.up" : "arrow.down"
      case .topTrailing: increment ? "arrow.up.right" : "arrow.down.left"
      case .trailing: increment ? "arrow.right" : "arrow.left"
      case .bottomTrailing: increment ? "arrow.down.right" : "arrow.up.left"
      case .bottom: increment ? "arrow.down" : "arrow.up"
      case .bottomLeading: increment ? "arrow.down.left" : "arrow.up.right"
      }
    }

    func displayValue(increment: Bool) -> String {
      switch self {
      case .leading: increment ? "←" : "→"
      case .topLeading: increment ? "↖" : "↘"
      case .top: increment ? "↑" : "↓"
      case .topTrailing: increment ? "↗" : "↙"
      case .trailing: increment ? "→" : "←"
      case .bottomTrailing: increment ? "↘" : "↖"
      case .bottom: increment ? "↓" : "↑"
      case .bottomLeading: increment ? "↙" : "↗"
      }
    }
  }

  enum Kind: Identifiable, Hashable, Codable {
    var id: String {
      switch self {
      case .fullscreen: "fullscreen"
      case .center: "center"
      case .decreaseSize(let byValue, let direction, _): "decreaseSize:\(byValue)\(direction.rawValue)"
      case .increaseSize(let byValue, let direction, let padding, _): "increaseSize:\(byValue)\(direction.rawValue):\(padding)"
      case .move(let toValue, let direction, let padding , _): "move:\(toValue)\(direction.rawValue):\(padding)"
      case .moveToNextDisplay(let mode): "moveToNextDisplay.\(mode.rawValue)"
      case .anchor: "anchor"
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
      case .center: "Center Window"
      case .fullscreen: "Fullscreen"
      case .move: "Move Window"
      case .decreaseSize: "Shrink Window"
      case .increaseSize: "Grow Window"
      case .moveToNextDisplay(let mode): "Move to Next Display - \(mode.displayValue)"
      case .anchor: "Anchor and Resize Window"
      }
    }

    var symbol: String {
      switch self {
      case .center: "arrow.down.right.and.arrow.up.left"
      case .fullscreen: "arrow.up.left.and.arrow.down.right"
      case .move: "arrow.up.and.down.and.arrow.left.and.right"
      case .decreaseSize: "minus.magnifyingglass"
      case .increaseSize: "plus.magnifyingglass"
      case .moveToNextDisplay: "rectangle.on.rectangle"
      case .anchor: "pin"
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

  func copy() -> WindowCommand {
    return WindowCommand(
      id: UUID().uuidString,
      name: meta.name,
      kind: kind,
      notification: meta.notification,
      animationDuration: animationDuration
    )
  }
}

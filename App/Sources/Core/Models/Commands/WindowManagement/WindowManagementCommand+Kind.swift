extension WindowManagementCommand {
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
      let container = try decoder.container(keyedBy: WindowManagementCommand.Kind.CodingKeys.self)
      var allKeys = ArraySlice(container.allKeys)
      guard let onlyKey = allKeys.popFirst(), allKeys.isEmpty else {
        throw DecodingError.typeMismatch(WindowManagementCommand.Kind.self, DecodingError.Context.init(codingPath: container.codingPath, debugDescription: "Invalid number of keys found, expected one.", underlyingError: nil))
      }
      switch onlyKey {
      case .increaseSize:
        let nestedContainer = try container.nestedContainer(keyedBy: WindowManagementCommand.Kind.IncreaseSizeCodingKeys.self, forKey: WindowManagementCommand.Kind.CodingKeys.increaseSize)
        self = WindowManagementCommand.Kind.increaseSize(
          by: try nestedContainer.decode(Int.self, forKey: WindowManagementCommand.Kind.IncreaseSizeCodingKeys.by),
          direction: try nestedContainer.decode(WindowManagementCommand.Direction.self, forKey: WindowManagementCommand.Kind.IncreaseSizeCodingKeys.direction),
          padding: try nestedContainer.decodeIfPresent(Int.self, forKey: WindowManagementCommand.Kind.IncreaseSizeCodingKeys.padding) ?? 0,
          constrainedToScreen: try nestedContainer.decode(Bool.self, forKey: WindowManagementCommand.Kind.IncreaseSizeCodingKeys.constrainedToScreen)
        )
      case .decreaseSize:
        let nestedContainer = try container.nestedContainer(keyedBy: WindowManagementCommand.Kind.DecreaseSizeCodingKeys.self, forKey: WindowManagementCommand.Kind.CodingKeys.decreaseSize)
        self = WindowManagementCommand.Kind.decreaseSize(
          by: try nestedContainer.decode(Int.self, forKey: WindowManagementCommand.Kind.DecreaseSizeCodingKeys.by),
          direction: try nestedContainer.decode(WindowManagementCommand.Direction.self, forKey: WindowManagementCommand.Kind.DecreaseSizeCodingKeys.direction),
          constrainedToScreen: try nestedContainer.decode(Bool.self, forKey: WindowManagementCommand.Kind.DecreaseSizeCodingKeys.constrainedToScreen)
        )
      case .move:
        let nestedContainer = try container.nestedContainer(keyedBy: WindowManagementCommand.Kind.MoveCodingKeys.self, forKey: WindowManagementCommand.Kind.CodingKeys.move)
        self = WindowManagementCommand.Kind.move(
          by: try nestedContainer.decode(Int.self, forKey: WindowManagementCommand.Kind.MoveCodingKeys.by),
          direction: try nestedContainer.decode(WindowManagementCommand.Direction.self, forKey: WindowManagementCommand.Kind.MoveCodingKeys.direction),
          padding: try nestedContainer.decodeIfPresent(Int.self, forKey: WindowManagementCommand.Kind.MoveCodingKeys.padding) ?? 0,
          constrainedToScreen: try nestedContainer.decode(Bool.self, forKey: WindowManagementCommand.Kind.MoveCodingKeys.constrainedToScreen)
        )
      case .fullscreen:
        let nestedContainer = try container.nestedContainer(keyedBy: WindowManagementCommand.Kind.FullscreenCodingKeys.self, forKey: WindowManagementCommand.Kind.CodingKeys.fullscreen)
        self = WindowManagementCommand.Kind.fullscreen(
          padding: try nestedContainer.decode(Int.self, forKey: WindowManagementCommand.Kind.FullscreenCodingKeys.padding)
        )
      case .center:
        self = WindowManagementCommand.Kind.center
      case .moveToNextDisplay:
        let nestedContainer = try container.nestedContainer(
          keyedBy: WindowManagementCommand.Kind.MoveToNextDisplayCodingKeys.self,
          forKey: WindowManagementCommand.Kind.CodingKeys.moveToNextDisplay
        )
        self = WindowManagementCommand.Kind.moveToNextDisplay(mode: try nestedContainer.decode(WindowManagementCommand.Mode.self, forKey: WindowManagementCommand.Kind.MoveToNextDisplayCodingKeys.mode))
      case .anchor:
        let nestedContainer = try container.nestedContainer(keyedBy: WindowManagementCommand.Kind.AnchorCodingKeys.self, forKey: WindowManagementCommand.Kind.CodingKeys.anchor)
        self = WindowManagementCommand.Kind.anchor(
          position: try nestedContainer.decode(WindowManagementCommand.Direction.self, forKey: WindowManagementCommand.Kind.AnchorCodingKeys.position),
          padding: try nestedContainer.decode(Int.self, forKey: WindowManagementCommand.Kind.AnchorCodingKeys.padding)
        )
      }
    }
  }
}

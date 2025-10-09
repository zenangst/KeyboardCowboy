extension MouseCommand {
  enum ClickLocation: Identifiable, Hashable, Codable, Equatable {
    var id: String { identifier }

    case topLeading
    case top
    case topTrailing
    case leading
    case center
    case trailing
    case bottomLeading
    case bottom
    case bottomTrailing
    case custom(x: Int, y: Int)

    static let allCases: [ClickLocation] = [
      .topLeading,
      .top,
      .topTrailing,
      .leading,
      .center,
      .trailing,
      .bottomLeading,
      .bottom,
      .bottomTrailing,
      .custom(x: 0, y: 0),
    ]

    var identifier: String {
      switch self {
      case .topLeading: "topLeading"
      case .top: "top"
      case .topTrailing: "topTrailing"
      case .leading: "leading"
      case .center: "center"
      case .trailing: "trailing"
      case .bottomLeading: "bottomLeading"
      case .bottom: "bottom"
      case .bottomTrailing: "bottomTrailing"
      case let .custom(x, y): "custom:\(x)x\(y)"
      }
    }

    var displayValue: String {
      switch self {
      case .topLeading: "Top Leading"
      case .top: "Top"
      case .topTrailing: "Top Trailing"
      case .leading: "Leading"
      case .center: "Center"
      case .trailing: "Trailing"
      case .bottomLeading: "Bottom Leading"
      case .bottom: "Bottom"
      case .bottomTrailing: "Bottom Trailing"
      case .custom: "Custom"
      }
    }
  }
}

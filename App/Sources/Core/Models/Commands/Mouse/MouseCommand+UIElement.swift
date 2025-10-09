extension MouseCommand {
  enum UIElement: Codable, Hashable, Equatable {
    case focused(ClickLocation)

    var displayValue: String {
      switch self {
      case .focused:
        "Focused Element"
      }
    }

    var clickLocation: ClickLocation {
      get {
        switch self {
        case let .focused(clickLocation):
          clickLocation
        }
      }
      set {
        switch self {
        case .focused:
          self = .focused(newValue)
        }
      }
    }
  }
}

extension MouseCommand {
  enum UIElement: Codable, Hashable, Equatable {
    case focused(ClickLocation)

    var displayValue: String {
      switch self {
      case .focused:
        return "Focused Element"
      }
    }

    var clickLocation: ClickLocation {
      get {
        switch self {
        case .focused(let clickLocation):
          return clickLocation
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

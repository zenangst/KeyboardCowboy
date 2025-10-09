extension WindowFocusCommand {
  enum Kind: String, Identifiable, CaseIterable, Codable {
    var id: String { rawValue }

    case moveFocusToNextWindowOnLeft
    case moveFocusToNextWindowOnRight
    case moveFocusToNextWindowUpwards
    case moveFocusToNextWindowDownwards

    case moveFocusToNextWindowUpperLeftQuarter
    case moveFocusToNextWindowUpperRightQuarter
    case moveFocusToNextWindowLowerLeftQuarter
    case moveFocusToNextWindowLowerRightQuarter

    case moveFocusToNextWindowCenter

    case moveFocusToNextWindowFront
    case moveFocusToPreviousWindowFront
    case moveFocusToNextWindow
    case moveFocusToPreviousWindow
    case moveFocusToNextWindowGlobal
    case moveFocusToPreviousWindowGlobal

    var displayValue: String {
      switch self {
      case .moveFocusToNextWindowGlobal: "Move Focus to Next Window (All Windows)"
      case .moveFocusToPreviousWindowGlobal: "Move Focus to Previous window (All Windows)"
      case .moveFocusToNextWindow: "Move Focus to Next Window"
      case .moveFocusToPreviousWindow: "Move Focus to Previous Window"
      case .moveFocusToNextWindowFront: "Move Focus to Next Window of Active Application"
      case .moveFocusToPreviousWindowFront: "Move Focus to Previous Window of Active Application"
      case .moveFocusToNextWindowUpwards: "Move Focus to Window Upwards"
      case .moveFocusToNextWindowOnLeft: "Move Focus to Window on Left"
      case .moveFocusToNextWindowOnRight: "Move Focus to Window on Right"
      case .moveFocusToNextWindowDownwards: "Move Focus to Window Downwards"
      case .moveFocusToNextWindowCenter: "Move Focus to Window in Center"
      case .moveFocusToNextWindowUpperLeftQuarter: "Move Focus to Upper Left Quarter"
      case .moveFocusToNextWindowUpperRightQuarter: "Move Focus to Upper Right Quarter"
      case .moveFocusToNextWindowLowerLeftQuarter: "Move Focus to Lower Left Quarter"
      case .moveFocusToNextWindowLowerRightQuarter: "Move Focus to Lower Right Quarter"
      }
    }

    var symbol: String {
      switch self {
      case .moveFocusToNextWindowOnLeft: "arrow.left.circle"
      case .moveFocusToNextWindowOnRight: "arrow.right.circle"
      case .moveFocusToNextWindowUpwards: "arrow.up.circle"
      case .moveFocusToNextWindowDownwards: "arrow.down.circle"
      case .moveFocusToNextWindowCenter: "arrow.up.right.and.arrow.down.left"
      case .moveFocusToNextWindowGlobal: "arrow.right.circle"
      case .moveFocusToPreviousWindowGlobal: "arrow.left.circle"
      case .moveFocusToNextWindow: "arrow.right.to.line.alt"
      case .moveFocusToPreviousWindow: "arrow.left.to.line.alt"
      case .moveFocusToNextWindowFront: "arrow.forward.circle"
      case .moveFocusToPreviousWindowFront: "arrow.backward.circle"
      case .moveFocusToNextWindowUpperLeftQuarter: "arrow.up.left.circle"
      case .moveFocusToNextWindowUpperRightQuarter: "arrow.up.right.circle"
      case .moveFocusToNextWindowLowerLeftQuarter: "arrow.down.left.circle"
      case .moveFocusToNextWindowLowerRightQuarter: "arrow.down.right.circle"
      }
    }
  }
}

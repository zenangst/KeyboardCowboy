public extension WindowTiling {
  enum Action: String, CaseIterable, Codable, Sendable {
    case left, right, top, bottom
    case topLeft, topRight, bottomLeft, bottomRight
    case center, fill, zoom
    case arrangeLeftRight, arrangeRightLeft, arrangeTopBottom, arrangeBottomTop
    case arrangeLeftQuarters, arrangeRightQuarters, arrangeTopQuarters, arrangeBottomQuarters
    case arrangeDynamicQuarters, arrangeQuarters, previousSize

    var menuIdentifier: String {
      switch self {
      case .left: "_zoomLeft:"
      case .right: "_zoomRight:"
      case .top: "_zoomTop:"
      case .bottom: "_zoomBottom:"
      case .topLeft: "_zoomTopLeft:"
      case .topRight: "_zoomTopRight:"
      case .bottomLeft: "_zoomBottomLeft:"
      case .bottomRight: "_zoomBottomRight:"
      case .center: "_zoomCenter:"
      case .fill: "_zoomFill:"
      case .zoom: "performZoom:"
      case .arrangeLeftRight: "_zoomLeftAndRight:"
      case .arrangeRightLeft: "_zoomRightAndLeft:"
      case .arrangeTopBottom: "_zoomTopAndBottom:"
      case .arrangeBottomTop: "_zoomBottomAndTop:"
      case .arrangeLeftQuarters: "_zoomLeftThreeUp:"
      case .arrangeRightQuarters: "_zoomRightThreeUp:"
      case .arrangeTopQuarters: "_zoomTopThreeUp:"
      case .arrangeBottomQuarters: "_zoomBottomThreeUp:"
      case .arrangeDynamicQuarters: "_arrangeDynamicQuarters:"
      case .arrangeQuarters: "_zoomQuarters:"
      case .previousSize: "_zoomUntile:"
      }
    }

    var isDirectWindowMenuAction: Bool {
      switch self {
      case .center, .fill, .zoom: true
      default: false
      }
    }
  }
}

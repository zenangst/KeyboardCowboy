enum WindowTiling {
  case left
  case right
  case top
  case bottom
  case topLeft
  case topRight
  case bottomLeft
  case bottomRight
  case center
  case fill
  case zoom
  case arrangeLeftRight
  case arrangeRightLeft
  case arrangeTopBottom
  case arrangeBottomTop
  case arrangeLeftQuarters
  case arrangeRightQuarters
  case arrangeTopQuarters
  case arrangeBottomQuarters
  case arrangeDynamicQuarters
  case arrangeQuarters
  case previousSize

  var identifier: String {
    return switch self {
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
}

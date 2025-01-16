import Cocoa

enum WindowTiling: String, Codable, Hashable {
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

  var displayValue: String {
    switch self {
    case .left:  "Left"
    case .right: "Right"
    case .top: "Top"
    case .bottom: "Bottom"
    case .topLeft: "Top Left"
    case .topRight: "Top Right"
    case .bottomLeft: "Bottom Left"
    case .bottomRight: "Bottom Right"
    case .center: "Center"
    case .fill: "Fill"
    case .zoom: "Zoom"
    case .arrangeLeftRight: "Arrange Left Right"
    case .arrangeRightLeft: "Arrange Right Left"
    case .arrangeTopBottom: "Arrange Top Bottom"
    case .arrangeBottomTop: "Arrange Bottom Top"
    case .arrangeLeftQuarters: "Arrange Left Quarters"
    case .arrangeRightQuarters: "Arrange Right Quarters"
    case .arrangeTopQuarters: "Arrange Top Quarters"
    case .arrangeBottomQuarters: "Arrange Bottom Quarters"
    case .arrangeDynamicQuarters: "Arrange Dynamic Quarters"
    case .arrangeQuarters: "Arrange Quarters"
    case .previousSize: "Previous Size"
    }
  }

  var identifier: String {
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
}

extension WindowTiling {
  var revesed: WindowTiling {
    switch self {
    case .left:                   .right
    case .right:                  .left
    case .top:                    .bottom
    case .bottom:                 .top
    case .topLeft:                .topRight
    case .topRight:               .topLeft
    case .bottomLeft:             .bottomRight
    case .bottomRight:            .bottomLeft
    case .center:                 .center
    case .fill:                   .fill
    case .zoom:                   .zoom
    case .arrangeLeftRight:       .arrangeRightLeft
    case .arrangeRightLeft:       .arrangeLeftRight
    case .arrangeTopBottom:       .arrangeBottomTop
    case .arrangeBottomTop:       .arrangeTopBottom
    case .arrangeLeftQuarters:    .arrangeRightQuarters
    case .arrangeRightQuarters:   .arrangeLeftQuarters
    case .arrangeTopQuarters:     .arrangeBottomQuarters
    case .arrangeBottomQuarters:  .arrangeTopQuarters
    case .arrangeDynamicQuarters: .arrangeDynamicQuarters
    case .arrangeQuarters:        .arrangeQuarters
    case .previousSize:           .previousSize
    }
  }

  func rect(in visibleFrame: CGRect, spacing: CGFloat) -> CGRect? {
    let halfWidth = visibleFrame.width / 2
    let halfHeight = visibleFrame.height / 2
    let spacingX = spacing * 2
    let spacingY = spacing * 2
    let minX = visibleFrame.minX + spacing
    let midX = visibleFrame.midX + spacing
    let minY = visibleFrame.minY / 2 + spacing * 2
    let maxY = visibleFrame.maxY / 2 + spacing * 2

    switch self {
    case .left:
      return CGRect(
        origin: CGPoint(x: minX, y: minY),
        size: CGSize(
          width: halfWidth - spacingX,
          height: visibleFrame.height - spacingY
        )
      )
    case .right:
      return CGRect(
        origin: CGPoint(x: midX, y: minY),
        size: CGSize(
          width: halfWidth - spacingX,
          height: visibleFrame.height - spacingY
        )
      )
    case .top:
      return CGRect(
        origin: CGPoint(x: minX, y: minY),
        size: CGSize(
          width: visibleFrame.width - spacingX,
          height: halfHeight - spacingY
        )
      )
    case .bottom:
      return CGRect(
        origin: CGPoint(x: minX, y: maxY),
        size: CGSize(
          width: visibleFrame.width - spacingX,
          height: halfHeight - spacingY
        )
      )
    case .topLeft:
      return CGRect(
        origin: CGPoint(x: minX, y: minY),
        size: CGSize(
          width: halfWidth - spacingX,
          height: halfHeight - spacingY
        )
      )
    case .topRight:
      return CGRect(
        origin: CGPoint(x: midX, y: minY),
        size: CGSize(
          width: halfWidth - spacingX,
          height: halfHeight - spacingY
        )
      )
    case .bottomLeft:
      return CGRect(
        origin: CGPoint(x: minX, y: maxY),
        size: CGSize(
          width: halfWidth - spacingX,
          height: halfHeight - spacingY
        )
      )
    case .bottomRight:
      return CGRect(
        origin: CGPoint(x: midX, y: maxY),
        size: CGSize(
          width: halfWidth - spacingX,
          height: halfHeight - spacingY
        )
      )
    case .fill:
      return visibleFrame
        .insetBy(dx: spacing, dy: spacing)
    default:
      return nil
    }
  }
}

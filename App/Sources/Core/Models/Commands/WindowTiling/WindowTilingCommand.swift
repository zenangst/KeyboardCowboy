import Foundation

struct WindowTilingCommand: MetaDataProviding {
  var kind: WindowTiling
  var meta: Command.MetaData

  func copy() -> WindowTilingCommand {
    WindowTilingCommand(kind: kind, meta: meta.copy())
  }
}

extension WindowTiling {
  var descriptiveValue: String {
    switch self {
    case .left: "Window › Move & Resize › Left"
    case .right: "Window › Move & Resize › Right"
    case .top: "Window › Move & Resize › Top"
    case .bottom: "Window › Move & Resize › Bottom"
    case .topLeft: "Window › Move & Resize › Top Left"
    case .topRight: "Window › Move & Resize › Top Right"
    case .bottomLeft: "Window › Move & Resize › Bottom Left"
    case .bottomRight: "Window › Move & Resize › Bottom Right"
    case .center: "Window › Center"
    case .fill: "Window › Fill"
    case .zoom: "Window › Zoom"
    case .arrangeLeftRight: "Window › Move & Resize › Left & Right"
    case .arrangeRightLeft: "Window › Move & Resize › Right & Left"
    case .arrangeTopBottom: "Window › Move & Resize › Top & Bottom"
    case .arrangeBottomTop: "Window › Move & Resize › Bottom & Top"
    case .arrangeLeftQuarters: "Window › Move & Resize › Left & Quarters"
    case .arrangeRightQuarters: "Window › Move & Resize › Right & Quarters"
    case .arrangeTopQuarters: "Window › Move & Resize › Top & Quarters"
    case .arrangeBottomQuarters: "Window › Move & Resize › Bottom & Quarters"
    case .arrangeDynamicQuarters: "Window › Move & Resize › Dynamic & Quarters"
    case .arrangeQuarters: "Window › Move & Resize › Quarters"
    case .previousSize: "Window › Move & Resize › Return to Previous Size"
    }
  }

  var symbol: String {
    switch self {
    case .left: "rectangle.split.2x1"
    case .right: "rectangle.split.2x1"
    case .top: "square.split.1x2"
    case .bottom: "square.split.1x2"
    case .topLeft: "square.split.bottomrightquarter"
    case .topRight: "square.split.bottomrightquarter"
    case .bottomLeft: "square.split.bottomrightquarter"
    case .bottomRight: "square.split.bottomrightquarter"
    case .center: "square.split.diagonal.2x2.fill"
    case .fill: "square.fill"
    case .zoom: "square.arrowtriangle.4.outward"
    case .arrangeLeftRight: "rectangle.split.2x1.fill"
    case .arrangeRightLeft: "rectangle.split.2x1.fill"
    case .arrangeTopBottom: "rectangle.split.1x2.fill"
    case .arrangeBottomTop: "rectangle.split.1x2.fill"
    case .arrangeLeftQuarters: "uiwindow.split.2x1"
    case .arrangeRightQuarters: "uiwindow.split.2x1"
    case .arrangeTopQuarters: "uiwindow.split.2x1"
    case .arrangeBottomQuarters: "uiwindow.split.2x1"
    case .arrangeDynamicQuarters: "uiwindow.split.2x1"
    case .arrangeQuarters: "square.split.2x2"
    case .previousSize: "arrow.uturn.backward.circle.fill"
    }
  }
}

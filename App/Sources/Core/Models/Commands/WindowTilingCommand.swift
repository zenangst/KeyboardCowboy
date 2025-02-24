import Foundation

struct WindowTilingCommand: MetaDataProviding {
  var kind: Kind
  var meta: Command.MetaData

  enum Kind: String, Identifiable, CaseIterable, Codable {
    var id: String { rawValue }

    case windowTilingLeft
    case windowTilingRight
    case windowTilingTop
    case windowTilingBottom
    case windowTilingTopLeft
    case windowTilingTopRight
    case windowTilingBottomLeft
    case windowTilingBottomRight
    case windowTilingCenter

    case windowTilingFill
    case windowTilingZoom

    case windowTilingArrangeLeftRight
    case windowTilingArrangeRightLeft
    case windowTilingArrangeTopBottom
    case windowTilingArrangeBottomTop
    case windowTilingArrangeLeftQuarters
    case windowTilingArrangeRightQuarters
    case windowTilingArrangeTopQuarters
    case windowTilingArrangeBottomQuarters
    case windowTilingArrangeDynamicQuarters
    case windowTilingArrangeQuarters

    case windowTilingPreviousSize
  }

  func copy() -> WindowTilingCommand {
    WindowTilingCommand(kind: kind, meta: meta.copy())
  }
}

extension WindowTilingCommand.Kind {
  var displayValue: String {
    switch self {
    case .windowTilingLeft: "Window › Move & Resize › Left"
    case .windowTilingRight: "Window › Move & Resize › Right"
    case .windowTilingTop: "Window › Move & Resize › Top"
    case .windowTilingBottom: "Window › Move & Resize › Bottom"
    case .windowTilingTopLeft: "Window › Move & Resize › Top Left"
    case .windowTilingTopRight: "Window › Move & Resize › Top Right"
    case .windowTilingBottomLeft: "Window › Move & Resize › Bottom Left"
    case .windowTilingBottomRight: "Window › Move & Resize › Bottom Right"
    case .windowTilingCenter: "Window › Center"
    case .windowTilingFill: "Window › Fill"
    case .windowTilingZoom: "Window › Zoom"
    case .windowTilingArrangeLeftRight: "Window › Move & Resize › Left & Right"
    case .windowTilingArrangeRightLeft: "Window › Move & Resize › Right & Left"
    case .windowTilingArrangeTopBottom: "Window › Move & Resize › Top & Bottom"
    case .windowTilingArrangeBottomTop: "Window › Move & Resize › Bottom & Top"
    case .windowTilingArrangeLeftQuarters: "Window › Move & Resize › Left & Quarters"
    case .windowTilingArrangeRightQuarters: "Window › Move & Resize › Right & Quarters"
    case .windowTilingArrangeTopQuarters: "Window › Move & Resize › Top & Quarters"
    case .windowTilingArrangeBottomQuarters: "Window › Move & Resize › Bottom & Quarters"
    case .windowTilingArrangeDynamicQuarters: "Window › Move & Resize › Dynamic & Quarters"
    case .windowTilingArrangeQuarters: "Window › Move & Resize › Quarters"
    case .windowTilingPreviousSize: "Window › Move & Resize › Return to Previous Size"
    }
  }

  var symbol: String {
    switch self {
    case .windowTilingLeft: "rectangle.split.2x1"
    case .windowTilingRight: "rectangle.split.2x1"
    case .windowTilingTop: "square.split.1x2"
    case .windowTilingBottom: "square.split.1x2"
    case .windowTilingTopLeft: "square.split.bottomrightquarter"
    case .windowTilingTopRight: "square.split.bottomrightquarter"
    case .windowTilingBottomLeft: "square.split.bottomrightquarter"
    case .windowTilingBottomRight: "square.split.bottomrightquarter"
    case .windowTilingCenter: "square.split.diagonal.2x2.fill"
    case .windowTilingFill: "square.fill"
    case .windowTilingZoom: "square.arrowtriangle.4.outward"
    case .windowTilingArrangeLeftRight: "rectangle.split.2x1.fill"
    case .windowTilingArrangeRightLeft: "rectangle.split.2x1.fill"
    case .windowTilingArrangeTopBottom: "rectangle.split.1x2.fill"
    case .windowTilingArrangeBottomTop: "rectangle.split.1x2.fill"
    case .windowTilingArrangeLeftQuarters, .windowTilingArrangeDynamicQuarters: "uiwindow.split.2x1"
    case .windowTilingArrangeRightQuarters: "uiwindow.split.2x1"
    case .windowTilingArrangeTopQuarters: "uiwindow.split.2x1"
    case .windowTilingArrangeBottomQuarters: "uiwindow.split.2x1"
    case .windowTilingArrangeQuarters: "square.split.2x2"
    case .windowTilingPreviousSize: "arrow.uturn.backward.circle.fill"
    }
  }
}

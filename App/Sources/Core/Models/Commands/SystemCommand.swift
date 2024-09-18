import Foundation

struct SystemCommand: MetaDataProviding {
  enum Kind: String, Identifiable, Codable, CaseIterable {
    var id: String { rawValue }

    var displayValue: String {
      switch self {
      case .activateLastApplication:         "Activate Last Application"
      case .applicationWindows:              "Application Windows"
      case .minimizeAllOpenWindows:          "Minimize All Open Windows"
      case .hideAllApps:                     "Hide All Apps"
      case .missionControl:                  "Mission Control"
      case .showDesktop:                     "Show Desktop"
      case .moveFocusToNextWindowGlobal:     "Move Focus to Next Window (All Windows)"
      case .moveFocusToPreviousWindowGlobal: "Move Focus to Previous window (All Windows)"
      case .moveFocusToNextWindow:           "Move Focus to Next Window"
      case .moveFocusToPreviousWindow:       "Move Focus to Previous Window"
      case .moveFocusToNextWindowFront:      "Move Focus to Next Window of Active Application"
      case .moveFocusToPreviousWindowFront:  "Move Focus to Previous Window of Active Application"
      case .moveFocusToNextWindowUpwards:    "Move Focus to Window Upwards"
      case .moveFocusToNextWindowOnLeft:     "Move Focus to Window on Left"
      case .moveFocusToNextWindowOnRight:    "Move Focus to Window on Right"
      case .moveFocusToNextWindowDownwards:  "Move Focus to Window Downwards"
      case .moveFocusToNextWindowCenter:     "Move Focus to Window in Center"
      case .moveFocusToNextWindowUpperLeftQuarter: "Move Focus to Upper Left Quarter"
      case .moveFocusToNextWindowUpperRightQuarter: "Move Focus to Upper Right Quarter"
      case .moveFocusToNextWindowLowerLeftQuarter: "Move Focus to Lower Left Quarter"
      case .moveFocusToNextWindowLowerRightQuarter: "Move Focus to Lower Right Quarter"
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
      case .windowTilingArrangeQuarters: "Window › Move & Resize › Quarters"
      case .windowTilingPreviousSize: "Window › Move & Resize › Return to Previous Size"

      }
    }

    var symbol: String {
      switch self {
      case .activateLastApplication:         "arrow.counterclockwise.circle"
      case .applicationWindows:              "rectangle.on.rectangle"
      case .minimizeAllOpenWindows:          "arrow.down.right.and.arrow.up.left"
      case .hideAllApps:                     "eye.slash"
      case .missionControl:                  "square.grid.3x3"
      case .showDesktop:                     "desktopcomputer"
      case .moveFocusToNextWindowOnLeft:     "arrow.left.circle"
      case .moveFocusToNextWindowOnRight:    "arrow.right.circle"
      case .moveFocusToNextWindowUpwards:    "arrow.up.circle"
      case .moveFocusToNextWindowDownwards:  "arrow.down.circle"
      case .moveFocusToNextWindowCenter:     "arrow.up.right.and.arrow.down.left"
      case .moveFocusToNextWindowGlobal:     "arrow.right.circle"
      case .moveFocusToPreviousWindowGlobal: "arrow.left.circle"
      case .moveFocusToNextWindow:           "arrow.right.to.line.alt"
      case .moveFocusToPreviousWindow:       "arrow.left.to.line.alt"
      case .moveFocusToNextWindowFront:      "arrow.forward.circle"
      case .moveFocusToPreviousWindowFront:  "arrow.backward.circle"
      case .moveFocusToNextWindowUpperLeftQuarter: "arrow.up.left.circle"
      case .moveFocusToNextWindowUpperRightQuarter: "arrow.up.right.circle"
      case .moveFocusToNextWindowLowerLeftQuarter: "arrow.down.left.circle"
      case .moveFocusToNextWindowLowerRightQuarter: "arrow.down.right.circle"
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
      case .windowTilingArrangeLeftQuarters: "uiwindow.split.2x1"
      case .windowTilingArrangeRightQuarters: "uiwindow.split.2x1"
      case .windowTilingArrangeTopQuarters: "uiwindow.split.2x1"
      case .windowTilingArrangeBottomQuarters: "uiwindow.split.2x1"
      case .windowTilingArrangeQuarters: "square.split.2x2"
      case .windowTilingPreviousSize: "arrow.uturn.backward.circle.fill"
      }
    }

    var iconPath: String {
      switch self {
      case .activateLastApplication:                                     "/System/Library/CoreServices/Family.app"
      case .applicationWindows:                                          "/System/Applications/Mission Control.app/Contents/Resources/AppIcon.icns"
      case .moveFocusToNextWindowFront:                                  "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
      case .moveFocusToPreviousWindowFront:                              "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
      case .moveFocusToNextWindow, .moveFocusToNextWindowGlobal:         "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
      case .moveFocusToPreviousWindow, .moveFocusToPreviousWindowGlobal: "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
      case .minimizeAllOpenWindows:                                      "/System/Applications/Mission Control.app/Contents/Resources/AppIcon.icns"
      case .hideAllApps:                                                 "/System/Applications/Mission Control.app/Contents/Resources/AppIcon.icns"
      case .missionControl:                                              "/System/Applications/Mission Control.app/Contents/Resources/AppIcon.icns"
      case .showDesktop:                                                 "/System/Library/CoreServices/Dock.app/Contents/Resources/Dock.icns"
      case .moveFocusToNextWindowOnLeft:                                 "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
      case .moveFocusToNextWindowOnRight:                                "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
      case .moveFocusToNextWindowUpwards:                                "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
      case .moveFocusToNextWindowDownwards:                              "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
      case .moveFocusToNextWindowCenter:                              "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
      case .moveFocusToNextWindowUpperLeftQuarter: "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
      case .moveFocusToNextWindowUpperRightQuarter: "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
      case .moveFocusToNextWindowLowerLeftQuarter: "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
      case .moveFocusToNextWindowLowerRightQuarter: "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
      case .windowTilingLeft: "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
      case .windowTilingRight: "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
      case .windowTilingTop: "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
      case .windowTilingBottom: "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
      case .windowTilingTopLeft: "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
      case .windowTilingTopRight: "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
      case .windowTilingBottomLeft: "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
      case .windowTilingBottomRight: "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
      case .windowTilingCenter: "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
      case .windowTilingFill: "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
      case .windowTilingZoom: "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
      case .windowTilingArrangeLeftRight: "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
      case .windowTilingArrangeRightLeft: "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
      case .windowTilingArrangeTopBottom: "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
      case .windowTilingArrangeBottomTop: "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
      case .windowTilingArrangeLeftQuarters: "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
      case .windowTilingArrangeRightQuarters: "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
      case .windowTilingArrangeTopQuarters: "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
      case .windowTilingArrangeBottomQuarters: "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
      case .windowTilingArrangeQuarters: "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
      case .windowTilingPreviousSize: "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
      }
    }

    case activateLastApplication
    case applicationWindows
    case minimizeAllOpenWindows
    case hideAllApps
    case missionControl
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
    case showDesktop
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
    case windowTilingArrangeQuarters
    case windowTilingPreviousSize
  }
  var kind: Kind
  var meta: Command.MetaData

  init(id: String = UUID().uuidString, name: String, kind: Kind, 
       notification: Command.Notification? = nil) {
    self.kind = kind
    self.meta = Command.MetaData(id: id, name: name, isEnabled: true, notification: notification)
  }

  init(kind: Kind, meta: Command.MetaData) {
    self.kind = kind
    self.meta = meta
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.kind = try container.decode(Kind.self, forKey: .kind)
    do {
      self.meta = try container.decode(Command.MetaData.self, forKey: .meta)
    } catch {
      self.meta = try MetaDataMigrator.migrate(decoder)
    }
  }

  func copy() -> SystemCommand {
    SystemCommand(kind: kind, meta: meta.copy())
  }
}

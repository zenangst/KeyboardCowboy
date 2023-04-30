import Foundation
import LaunchArguments
import CoreGraphics

let launchArguments = LaunchArgumentsController<LaunchArgument>()

func missionControlIsActive() -> Bool {
  let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as [AnyObject]? ?? []
  return !windows.filter { entry in
    guard let appName = entry[kCGWindowOwnerName as String] as? String,
          let layer = entry[kCGWindowLayer as String] as? Int,
          appName == "Dock" &&
          layer == CGWindowLevelKey.desktopIconWindow.rawValue else {
      return false
    }

    return true
  }.isEmpty
}

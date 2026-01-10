import AXEssibility

enum WindowTilingMenuItemFinder {
  static func find(_ tiling: WindowTiling, in menuItems: [MenuBarItemAccessibilityElement]) -> MenuBarItemAccessibilityElement? {
    var menuBarMatch: MenuBarItemAccessibilityElement?
    switch tiling {
    case .zoom, .fill, .center:
      let items = menuItems.windowMenuBarItems
      for item in items {
        if item.identifier == tiling.identifier {
          menuBarMatch = item
          break
        }
      }
    default:
      let items = menuItems.windowMoveAndResizeItems
      for item in items {
        if item.identifier == tiling.identifier {
          menuBarMatch = item
          break
        }
      }
    }

    return menuBarMatch
  }
}

extension [MenuBarItemAccessibilityElement] {
  var windowMoveAndResizeItems: [MenuBarItemAccessibilityElement] {
    for menuItem in windowMenuBarItems where menuItem.isSubMenu {
      if let submenu = try? menuItem.menuItems().first,
         let menuItems = try? submenu.menuItems() {
        for item in menuItems where item.isEnabled == true {
          if item.identifier == WindowTiling.left.identifier {
            return menuItems
          }
        }
      }
    }

    return []
  }

  var windowMenuBarItems: [MenuBarItemAccessibilityElement] {
    for menuItem in self.reversed() {
      if menuItem.isSubMenu,
         let submenu = try? menuItem.menuItems().first,
         let menuItems = try? submenu.menuItems() {
        for item in menuItems where item.isEnabled == true {
          if item.identifier == WindowTiling.center.identifier {
            return menuItems
          }
        }
      }
    }
    return []
  }
}

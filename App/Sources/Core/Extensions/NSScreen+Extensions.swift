import Cocoa

extension NSScreen {
  func isMirrored() -> Bool {
    guard let screenNumber = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
      return false
    }

    return CGDisplayIsInMirrorSet(screenNumber) != 0
  }

  private func findNextScreen(in direction: WindowTiling, cycling: Bool) -> NSScreen? {
    let screens = NSScreen.screens

    func screenMatches(_ candidate: NSScreen, direction: WindowTiling, relativeTo currentScreen: NSScreen) -> Bool {
      switch direction {
      case .left:
        candidate.frame.maxX <= currentScreen.frame.minX
      case .right:
        candidate.frame.minX >= currentScreen.frame.maxX
      case .top:
        candidate.frame.minY >= currentScreen.frame.maxY
      case .bottom:
        candidate.frame.maxY <= currentScreen.frame.minY
      default:
        false
      }
    }

    let nextScreen = screens.first(where: { screenMatches($0, direction: direction, relativeTo: self) })

    if let foundScreen = nextScreen {
      return foundScreen
    }

    if cycling {
      switch direction {
      case .left:
        return screens.last
      case .right:
        return screens.first
      case .top:
        return screens.first(where: { $0.frame.maxY > self.frame.maxY }) ?? screens.first
      case .bottom:
        return screens.first(where: { $0.frame.minY < self.frame.minY }) ?? screens.first
      default:
        return nil
      }
    }

    return nil
  }
}

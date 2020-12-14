import Cocoa

enum ApplicationAction {
  case toggleSidebar
  case showSidebar
}

extension NSApplication {
  private func invoke(_ action: Selector) {
    keyWindow?.firstResponder?.tryToPerform(action, with: nil)
  }

  func tryToPerform(_ action: ApplicationAction) {

    switch action {
    case .toggleSidebar:
      invoke(#selector(NSSplitViewController.toggleSidebar(_:)))
    case .showSidebar:
      let splitView = (keyWindow?.firstResponder as? NSWindow)?.contentView?.find(NSSplitView.self)
      splitView?.subviews.first?.isHidden = false
    }
  }
}

extension NSView {
  func find<T: NSView>(_ ofType: T.Type) -> T? {
    if let test = subviews.first(where: { $0 is T }) as? T {
      return test
    } else {
      for view in subviews {
        return view.find(ofType)
      }
    }
    return nil
  }
}

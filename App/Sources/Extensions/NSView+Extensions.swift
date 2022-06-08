import Cocoa

extension NSView {
  func findSubview<T: NSView>(_ ofType: T.Type) -> T? {
    if let match = subviews.first(where: { $0 is T }) as? T {
      return match
    } else {
      for view in subviews {
        return view.findSubview(ofType)
      }
    }
    return nil
  }

  func findSuperview<T: NSView>(_ ofType: T.Type) -> T? {
    guard let superview = superview else { return nil }
    if let match = superview as? T {
      return match
    } else {
      return superview.findSuperview(ofType)
    }
  }
}

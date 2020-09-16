import Cocoa

public protocol NotificationControlling {
  func addObserver(_ observer: Any, selector aSelector: Selector,
                   name aName: NSNotification.Name?, object anObject: Any?)
}

extension NotificationCenter: NotificationControlling {}

import Foundation

func enableInjection(_ observer: some Any, selector: Selector) {
  NotificationCenter.default.addObserver(
    observer,
    selector: selector,
    name: NSNotification.Name(rawValue: "INJECTION_BUNDLE_NOTIFICATION"),
    object: nil,
  )
}

func didInject(_ observer: some Any, notification: Notification) -> Bool {
  guard let array = notification.object as? [AnyObject] else { return false }

  let identifiers = array.map { "\($0)" }
  let selfIdentifier = "\(observer)"
  return identifiers.contains(selfIdentifier)
}

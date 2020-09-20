import Foundation
import LogicFramework

class NotificationControllerMock: NotificationControlling {
  func addObserver(_ observer: Any, selector aSelector: Selector,
                   name aName: NSNotification.Name?,
                   object anObject: Any?) {}
}

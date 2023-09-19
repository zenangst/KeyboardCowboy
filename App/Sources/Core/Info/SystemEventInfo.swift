import Foundation
import IOKit.pwr_mgt

class SystemEventInfo {
  var sleepNotification: io_object_t = 0
  var wakeNotification: io_object_t = 0

  init() {
    

    /*
    let sleepCallback: IOServiceInterestCallback = { (context, service, messageType, messageArgument) in
      let systemEventInfo = Unmanaged<SystemEventInfo>.fromOpaque(context!).takeUnretainedValue()
      systemEventInfo.handleSleepEvent()
    }

    let wakeCallback: IOServiceInterestCallback = { (context, service, messageType, messageArgument) in
      let systemEventInfo = Unmanaged<SystemEventInfo>.fromOpaque(context!).takeUnretainedValue()
      systemEventInfo.handleWakeEvent()
    }

    let selfPointer = Unmanaged.passUnretained(self).toOpaque()
    let notificationPort = kIOMainPortDefault
    let interest = kIOGeneralInterest

//    IOServiceAddInterestNotification(kIOMainPortDefault, kIOSystemPowerStateInterest, sleepCallback, selfPointer, &sleepNotification)
//    IOServiceAddInterestNotification(kIOMainPortDefault, kIOPowerPlaneInterest, wakeCallback, selfPointer, &wakeNotification)

//    CFRunLoopAddSource(CFRunLoopGetCurrent(), IONotificationPortGetRunLoopSource(IOServiceGetNotificationPort(sleepNotification)), .defaultMode)
//    CFRunLoopAddSource(CFRunLoopGetCurrent(), IONotificationPortGetRunLoopSource(IOServiceGetNotificationPort(wakeNotification)), .defaultMode)
     */
  }

  func handleSleepEvent() {
    print("System is going to sleep")
    // Add your code here to handle sleep event
  }

  func handleWakeEvent() {
    print("System is waking up")
    // Add your code here to handle wake event
  }

  deinit {
    IOObjectRelease(sleepNotification)
    IOObjectRelease(wakeNotification)
  }
}

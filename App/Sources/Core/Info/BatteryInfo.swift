import Foundation
import IOKit.ps

final class BatteryInfo: @unchecked Sendable {
  struct Model: Equatable {
    let acPowered: Bool?
    let currentCapacity: Float
    let isLowPowerModeEnabled: Bool
    let isCharged: Bool?
    let isCharging: Bool?

    init(acPowered: Bool?,
         currentCapacity: Float,
         isLowPowerModeEnabled: Bool = ProcessInfo.processInfo.isLowPowerModeEnabled,
         isCharging: Bool?,
         isCharged: Bool?) {
      self.acPowered = acPowered
      self.currentCapacity = currentCapacity
      self.isLowPowerModeEnabled = isLowPowerModeEnabled
      self.isCharged = isCharged
      self.isCharging = isCharging
    }
  }

  static let shared: BatteryInfo = .init()

  @Published private(set) var data: Model?

  private init() {
    subscribe()
    data = getBatteryInfo()
  }

  // Based on https://stackoverflow.com/a/57145146
  private func getBatteryInfo() -> Model? {
    let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
    defer {
      IOServiceClose(service)
      IOObjectRelease(service)
    }

    let powerSourceInfo = IOPSCopyPowerSourcesInfo().takeRetainedValue()
    let powerSources = IOPSCopyPowerSourcesList(powerSourceInfo).takeRetainedValue() as Array

    if powerSources.isEmpty {
      // If there aren't any power sources, we're probably running on a desktop.
      // So let's unsubscribe from battery events.
      unsubscribe()
      return nil
    }

    var batteryLevel: Float = -1

    for powerSource in powerSources {
      let powerSourceInfo = IOPSGetPowerSourceDescription(powerSourceInfo, powerSource).takeUnretainedValue() as! [String: Any]
      if let currentCapacity = powerSourceInfo[kIOPSCurrentCapacityKey] as? Int,
         let maxCapacity = powerSourceInfo[kIOPSMaxCapacityKey] as? Int {
        batteryLevel = Float(currentCapacity) / Float(maxCapacity)
      }
    }

    return Model(
      acPowered: service.bool("ExternalConnected"),
      currentCapacity: batteryLevel,
      isCharging: service.bool("IsCharging"),
      isCharged: service.bool("FullyCharged"),
    )
  }

  private func subscribe() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(batteryLevelDidChange(_:)),
      name: NSNotification.Name.NSProcessInfoPowerStateDidChange,
      object: nil,
    )
  }

  private func unsubscribe() {
    NotificationCenter.default.removeObserver(
      self,
      name: NSNotification.Name.NSProcessInfoPowerStateDidChange,
      object: nil,
    )
  }

  @objc private func batteryLevelDidChange(_: Notification) {
    data = getBatteryInfo()
  }
}

private extension io_service_t {
  func bool(_ forIdentifier: String) -> Bool? {
    IORegistryEntryCreateCFProperty(self, forIdentifier as CFString, kCFAllocatorDefault, 0)
      .takeRetainedValue() as? Bool
  }
}

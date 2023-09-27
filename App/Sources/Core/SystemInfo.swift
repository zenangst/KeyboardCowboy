import Combine
import Foundation

final class SystemInfo {
  struct Context {
    var wifi: WifiInfo.Model?
    var battery: BatteryInfo.Model?
  }

  @Published private(set) var context: Context

  let wifiInfo = WifiInfo.shared
  let batteryInfo = BatteryInfo.shared
  var subscriptions = [AnyCancellable]()

  init() { 
    self.context = .init()
    wifiInfo.$data
      .removeDuplicates()
      .sink { [weak self] in self?.context.wifi = $0 }
      .store(in: &subscriptions)

    batteryInfo.$data
      .removeDuplicates()
      .sink { [weak self] in self?.context.battery = $0 }
      .store(in: &subscriptions)
  }
}

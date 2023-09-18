import Foundation
import CoreWLAN
import SystemConfiguration.CaptiveNetwork

final class WifiInfo: CWEventDelegate {
  @Published private(set) var ssid: String?

  static let shared = WifiInfo()
  private let client = CWWiFiClient.shared()

  private init() {
    client.delegate = self
    startMonitoringSSIDChanges()
    ssid = client.interface()?.ssid()
  }

  func startMonitoringSSIDChanges() {
    try? client.startMonitoringEvent(with: .ssidDidChange)
  }

  func stopMonitoringSSIDChanges() {
    try? client.stopMonitoringEvent(with: .ssidDidChange)
  }

  func ssidDidChangeForWiFiInterface(withName interfaceName: String) {
    let ssid = client.interface(withName: interfaceName)?.ssid()
    self.ssid = ssid
  }
}

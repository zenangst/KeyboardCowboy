import CoreWLAN
import Foundation
import SystemConfiguration.CaptiveNetwork

enum WifiInfoError: Error {
  case needsPermissions
}

final class WifiInfo: CWEventDelegate, @unchecked Sendable {
  struct Model: Equatable {
    let ssid: String

    init?(ssid: String?) {
      guard let ssid else { return nil }

      self.ssid = ssid
    }
  }

  @Published private(set) var data: Model?

  static let shared = WifiInfo()
  private let client = CWWiFiClient.shared()

  private init() {
    client.delegate = self
    do {
      try startMonitoringSSIDChanges()
      data = Model(ssid: client.interface()?.ssid())
    } catch {
      print("Error starting WiFi monitoring: \(error)")
    }
  }

  func startMonitoringSSIDChanges() throws {
    guard LocationPermission.shared.permission != .authorizedAlways else {
      throw WifiInfoError.needsPermissions
    }

    try client.startMonitoringEvent(with: .ssidDidChange)
  }

  func stopMonitoringSSIDChanges() throws {
    try client.stopMonitoringEvent(with: .ssidDidChange)
  }

  func ssidDidChangeForWiFiInterface(withName interfaceName: String) {
    data = Model(ssid: client.interface(withName: interfaceName)?.ssid())
  }
}

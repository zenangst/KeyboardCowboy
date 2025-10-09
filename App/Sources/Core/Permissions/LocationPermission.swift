import AppKit
import AXEssibility
import CoreLocation
import Foundation

public enum PermissionsItemStatus: String {
  case request = "Request"
  case approved = "Approved"
  case pending = "Pending"
  case unknown = "Unknown"
}

final class LocationPermission: NSObject, ObservableObject, CLLocationManagerDelegate, @unchecked Sendable {
  enum Permission {
    case authorizedAlways
    case notDetermined
    case denied
    case restricted
    case unknown
  }

  static let shared = LocationPermission()

  @Published private(set) var viewModel: PermissionsItemStatus = .request
  @Published private(set) var permission: Permission = .notDetermined

  private let manager = CLLocationManager()

  override private init() {
    super.init()

    manager.delegate = self
  }

  func requestPermission() {
    switch manager.authorizationStatus {
    case .notDetermined:
      manager.requestAlwaysAuthorization()
    case .authorizedAlways, .denied, .restricted:
      if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices") {
        viewModel = .pending
        NSWorkspace.shared.open(url)
      }
    @unknown default:
      break
    }
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    switch manager.authorizationStatus {
    case .authorizedAlways:
      permission = .authorizedAlways
      viewModel = .approved
    case .notDetermined:
      permission = .notDetermined
      viewModel = .unknown
    case .denied:
      permission = .denied
      viewModel = .request
    case .restricted:
      permission = .restricted
      viewModel = .request
    @unknown default:
      permission = .unknown
      viewModel = .request
    }
  }
}

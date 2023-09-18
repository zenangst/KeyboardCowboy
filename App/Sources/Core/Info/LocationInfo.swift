import Foundation
import CoreLocation

final class LocationInfo: NSObject, ObservableObject, CLLocationManagerDelegate {
  enum Permission {
    case authorizedAlways
    case notDetermined
    case denied
    case restricted
    case unknown
  }
  static let shared = LocationInfo()

  @Published private(set) var permission: Permission = .notDetermined

  private let manager = CLLocationManager()

  private override init() {
    super.init()

    manager.delegate = self
  }

  func requestPermission() {
    manager.requestAlwaysAuthorization()
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    switch manager.authorizationStatus {
    case .authorizedAlways:
      permission = .authorizedAlways
    case .notDetermined:
      permission = .notDetermined
    case .denied:
      permission = .denied
    case .restricted:
      permission = .restricted
    @unknown default:
      permission = .unknown
    }
  }
}

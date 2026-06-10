import SwiftUI

@MainActor
final class RootDependencies: ObservableObject {
  @Published var brand: any AppBrand = V4Brand()

  init() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(injected),
      name: NSNotification.Name(rawValue: "INJECTION_BUNDLE_NOTIFICATION"),
      object: nil,
    )
  }

  @objc func injected() {
    self.brand = V4Brand()

    print(brand)
  }
}

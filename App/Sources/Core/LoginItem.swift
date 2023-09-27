import Foundation
import ServiceManagement

public class LoginItem: ObservableObject {
  @Published var isEnabled: Bool {
    willSet {
      internal_isEnabled = newValue
    }
  }

  init() {
    isEnabled = SMAppService.mainApp.status == .enabled
  }

  private var internal_isEnabled: Bool {
    get {
      SMAppService.mainApp.status == .enabled
    }
    set {
      do {
        if newValue {
          if SMAppService.mainApp.status == .enabled {
            try? SMAppService.mainApp.unregister()
          }

          try? SMAppService.mainApp.register()
        } else {
          try? SMAppService.mainApp.unregister()
        }
      }
    }
  }
}

import Foundation

enum UserSettings: Sendable {
  enum WindowManager: Sendable {
    private static let userDefaults: UserDefaults = .init(suiteName: "com.apple.WindowManager")!

    static var tiledWindowSpacing: CGFloat {
      if userDefaults.bool(forKey: "EnableTiledWindowMargins") == false {
        0
      } else {
        if userDefaults.object(forKey: "TiledWindowSpacing") == nil {
          8
        } else {
          max(CGFloat(userDefaults.float(forKey: "TiledWindowSpacing")), 0)
        }
      }
    }

    static var tiledWindowMarginsEnabled: Bool { userDefaults.bool(forKey: "EnableTiledWindowMargins") == true }

    static var tiledWindowBorder: Bool { userDefaults.bool(forKey: "ShowTiledWindowBorder") }

    static var stageManagerEnabled: Bool {
      userDefaults.bool(forKey: "GloballyEnabled")
    }
  }
}

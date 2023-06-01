import Cocoa
import Sparkle

final class AppUpdater: NSObject, ObservableObject, SPUUpdaterDelegate {
  private var sparkle: SPUStandardUpdaterController!

  override init() {
    super.init()
    self.sparkle = SPUStandardUpdaterController(updaterDelegate: self, userDriverDelegate: nil)
  }

  func checkForUpdates() {
    NSApplication.shared.setActivationPolicy(.regular)
    NSApplication.shared.activate(ignoringOtherApps: true)
    self.sparkle.checkForUpdates(nil)
  }

  func updater(_ updater: SPUUpdater, mayPerform updateCheck: SPUUpdateCheck) throws { }
}

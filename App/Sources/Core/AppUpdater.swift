import Cocoa
import Sparkle

final class AppUpdater: NSObject, ObservableObject, SPUUpdaterDelegate {
  private var sparkle: SPUStandardUpdaterController!

  override init() {
    super.init()
    sparkle = SPUStandardUpdaterController(updaterDelegate: self, userDriverDelegate: nil)
  }

  @MainActor
  func checkForUpdates() {
    NSApplication.shared.setActivationPolicy(.regular)
    NSApplication.shared.activate(ignoringOtherApps: true)
    sparkle.checkForUpdates(nil)
  }

  func updater(_: SPUUpdater, mayPerform _: SPUUpdateCheck) throws {}
}

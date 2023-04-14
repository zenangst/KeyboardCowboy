import Cocoa
import ViewKit

class QuickRunWindowController: NSWindowController {
  let featureController: QuickRunFeatureController
  let viewController: QuickRunViewController

  init(window: EventWindow, featureController: QuickRunFeatureController) {
    self.featureController = featureController
    self.viewController = QuickRunViewController(
      window: window,
      quickRunFeatureController: featureController)
    super.init(window: window)
    window.setFrameAutosaveName("QuickRun")
    self.contentViewController = viewController
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

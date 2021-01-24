import Cocoa
import SwiftUI
import ViewKit

class QuickRunViewController: NSViewController {
  var shouldFocusOnQuickRunTextField: Bool = true
  lazy var customView: NSView = NSView()

  private let quickRunFeatureController: QuickRunFeatureController
  private let window: EventWindow

  init(window: EventWindow, quickRunFeatureController: QuickRunFeatureController) {
    self.window = window
    self.quickRunFeatureController = quickRunFeatureController
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    self.view = customView
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    let contentView = QuickRunView(
      shouldActivate: Binding<Bool>(
        get: { self.shouldFocusOnQuickRunTextField },
        set: { self.shouldFocusOnQuickRunTextField = $0 }),
      query: Binding<String>(
        get: { self.quickRunFeatureController.query },
        set: { self.quickRunFeatureController.query = $0 }),
      viewController: quickRunFeatureController.erase(),
      window: window)

    let hostingView = NSHostingView(rootView: contentView)
    view.addSubview(hostingView)
    hostingView.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      hostingView.topAnchor.constraint(equalTo: view.topAnchor),
      hostingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      hostingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      hostingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])
  }
}

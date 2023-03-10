import Cocoa
import SwiftUI

private struct OwningWindowKey: EnvironmentKey {
    static let defaultValue: NSPanel? = nil
}

extension EnvironmentValues {
  var owningWindow: NSPanel? {
    get { self[OwningWindowKey.self] }
    set { self[OwningWindowKey.self] = newValue }
  }
}

final class NotificationWindow<Content>: NSPanel where Content: View {
  @Binding var isPresented: Bool

  init(_ isPresented: Binding<Bool>,
       contentRect: CGRect,
       content rootView: @escaping () -> Content) {
    _isPresented = isPresented
    super.init(contentRect: contentRect, styleMask: [
      .borderless, .nonactivatingPanel
    ], backing: .buffered, defer: false)

    self.animationBehavior = .utilityWindow
    self.collectionBehavior.insert(.fullScreenAuxiliary)
    self.isFloatingPanel = true
    self.isMovable = false
    self.isMovableByWindowBackground = false
    self.level = .floating

    self.contentView = NSHostingView(
      rootView: rootView()
        .ignoresSafeArea()
        .environment(\.owningWindow, self)
    )
  }
}

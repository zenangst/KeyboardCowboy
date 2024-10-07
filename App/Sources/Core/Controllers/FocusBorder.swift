import AppKit
import Bonzai
import Inject
import SwiftUI

@MainActor
final class FocusBorder {
  var isEnabled: Bool = true
  var workItem: DispatchWorkItem?

  static var shared: FocusBorder { .init() }

  private init() {

  }

  func show(_ frame: CGRect, for duration: TimeInterval = 0.375) {
    guard isEnabled else { return }

    dismiss()

    let frame = frame.insetBy(dx: -3, dy: -3)
    let publisher = FocusBorderPublisher()
    let window = FocusBorderPanel(
      animationBehavior: .none,
      content: FocusBorderView(color: Color(.systemBrown), publisher: publisher))

    let workItem = DispatchWorkItem {
      withAnimation(.easeOut(duration: 0.1)) {
        publisher.opacity = 0
        window.orderBack(nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
          window.close()
        }
      }
    }

    self.workItem = workItem
    DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)

    withAnimation(nil) {
      window.setFrame(frame, display: false)
    }

    withAnimation(.easeIn(duration: 0.1)) {
      publisher.opacity = 0.75
    }

    window.orderFront(nil)
  }

  func dismiss() {
    guard let workItem else { return }
    DispatchQueue.main.async(execute: workItem)
  }
}

final class FocusBorderPublisher: ObservableObject {
  @Published var opacity: Double = 0
}

struct FocusBorderView: View {
  @ObserveInjection var inject
  @ObservedObject private var publisher: FocusBorderPublisher
  private let color: Color

  init(color: Color, publisher: FocusBorderPublisher) {
    self.color = color
    self.publisher = publisher
  }

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 12)
        .stroke(color, lineWidth: 3)
        .shadow(color: color, radius: 12, y: -12)
    }
    .opacity(publisher.opacity)
    .animation(.snappy, value: publisher.opacity)
    .padding(1)
    .disabled(true)
    .allowsHitTesting(false)
    .enableInjection()
  }
}

public final class FocusBorderPanel<Content>: NSPanel where Content: View {
  public override var canBecomeKey: Bool { false }
  public override var canBecomeMain: Bool { false }

  public init(animationBehavior: NSWindow.AnimationBehavior,
              contentRect: NSRect = .init(origin: .zero, size: .init(width: 200, height: 200)),
              styleMask: NSWindow.StyleMask = [.borderless, .nonactivatingPanel],
              content rootView: @autoclosure @escaping () -> Content) {
    super.init(contentRect: contentRect, styleMask: styleMask, backing: .buffered, defer: false)

    self.animationBehavior = animationBehavior
    self.collectionBehavior.insert(.fullScreenAuxiliary)
    self.collectionBehavior.insert(.canJoinAllSpaces)
    self.collectionBehavior.insert(.stationary)
    self.isOpaque = false
    self.isFloatingPanel = true
    self.isMovable = false
    self.isMovableByWindowBackground = false
    self.level = .screenSaver
    self.becomesKeyOnlyIfNeeded = false
    self.backgroundColor = .clear
    self.acceptsMouseMovedEvents = false
    self.hasShadow = false

    let rootView = rootView()
      .ignoresSafeArea()

    let contentViewController = NSHostingController(rootView: rootView)
    self.contentViewController = contentViewController
    setFrame(contentRect, display: false)
  }
}

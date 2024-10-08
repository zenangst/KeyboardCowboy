import AppKit
import Bonzai
import Inject
import SwiftUI

@MainActor
final class FocusBorder {
  var isEnabled: Bool = true
  var workItem: DispatchWorkItem?
  var previousWindow: NSWindow?

  static var shared: FocusBorder { .init() }

  private init() {

  }

  func show(_ frame: CGRect, for duration: TimeInterval = 0.375) {
    guard isEnabled else { return }

    let frame = frame.insetBy(dx: -2, dy: -2)
    let publisher = FocusBorderPublisher()
    let window = FocusBorderPanel(
      animationBehavior: .none,
      content: FocusBorderView(color: .systemBrown,
                               publisher: publisher))

    dismiss()

    let workItem = DispatchWorkItem {
      let newFrame = window.frame.insetBy(dx: -2, dy: -2)
      let duration = 0.125
      NSAnimationContext.runAnimationGroup { context in
        context.timingFunction =  CAMediaTimingFunction(name: .easeInEaseOut)
        context.duration = duration
        context.allowsImplicitAnimation = true
        context.completionHandler = { window.close() }
        window.contentView?.layer?.opacity = 0
        window.animator().setFrame(newFrame, display: true, animate: true)
      }
      withAnimation(.snappy(duration: duration)) {
        publisher.opacity = 0
      }
    }

    self.workItem = workItem
    DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)

    withAnimation(nil) {
      window.setFrame(frame, display: false)
    }

    withAnimation(.easeIn(duration: 0.1)) {
      publisher.opacity = 0.5
    }

    window.orderFront(nil)
    previousWindow = window
  }

  func dismiss() {
    guard let workItem else { return }
    previousWindow?.level = .init(-1)
    previousWindow?.orderBack(nil)
    DispatchQueue.main.async(execute: workItem)
  }
}

final class FocusBorderPublisher: ObservableObject {
  @Published var opacity: Double = 0
}

struct FocusBorderView: View {
  @ObserveInjection var inject
  @ObservedObject private var publisher: FocusBorderPublisher
  private let color: NSColor

  init(color: NSColor, publisher: FocusBorderPublisher) {
    self.color = color
    self.publisher = publisher
  }

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 12)
        .fill(
          LinearGradient(
            gradient: Gradient(stops: [
              .init(color: .clear, location: 0.5),
              .init(color: Color(color).opacity(0.2), location: 1.0),
            ]),
            startPoint: .bottom,
            endPoint: .top
          )
        )

      RoundedRectangle(cornerRadius: 12)
        .stroke(Color(color.blended(withFraction: 0.1, of: .black)!), lineWidth: 3)
        .shadow(color: Color(color.blended(withFraction: 0.2, of: .white)!), radius: 32, y: -12)
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
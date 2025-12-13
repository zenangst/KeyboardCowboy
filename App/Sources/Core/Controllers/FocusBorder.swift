import AppKit
import Bonzai
import HotSwiftUI
import SwiftUI

@MainActor
final class FocusBorder {
  var isEnabled: Bool = false
  var workItem: DispatchWorkItem?
  var previousWindow: NSWindow?

  static var shared: FocusBorder { .init() }

  private init() {}

  func show(_ frame: CGRect, for _: TimeInterval = 0.375) {
    guard isEnabled else { return }

    let frame = frame.insetBy(dx: -2, dy: -2)
    let publisher = FocusBorderPublisher()
    let window = FocusBorderPanel(
      animationBehavior: .none,
      content: FocusBorderView(color: .controlAccentColor,
                               frame: frame,
                               publisher: publisher),
    )

    dismiss()

    let duration = 0.1
    let workItem = DispatchWorkItem {
      let newFrame = window.frame.insetBy(dx: -2, dy: -2)
      NSAnimationContext.runAnimationGroup { context in
        context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        context.duration = duration
        context.allowsImplicitAnimation = true
        context.completionHandler = { window.close() }
        window.contentView?.layer?.opacity = 0
        window.animator().setFrame(newFrame, display: true, animate: true)
      }
      withAnimation(.snappy(duration: duration)) {
        publisher.opacity = 0
        publisher.displayed = false
      }
    }

    self.workItem = workItem
    DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)

    withAnimation(nil) {
      window.setFrame(frame, display: false)
    }

    withAnimation(.easeIn(duration: duration)) {
      publisher.opacity = 1.0
      publisher.displayed = true
    }

    window.orderFrontRegardless()
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
  @Published var displayed: Bool = false
  @Published var opacity: Double = 0
}

struct FocusBorderView: View {
  @ObserveInjection var inject
  @ObservedObject private var publisher: FocusBorderPublisher
  private let frame: CGRect
  private let color: NSColor

  init(color: NSColor, frame: CGRect, publisher: FocusBorderPublisher) {
    self.color = color
    self.frame = frame
    self.publisher = publisher
  }

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 12)
        .stroke(Color(color.blended(withFraction: 0.1, of: .black)!), lineWidth: 3)
        .shadow(color: Color(color.blended(withFraction: 0.2, of: .white)!), radius: 32, y: -12)
        .opacity(0.3)
    }
    .animation(.snappy, value: publisher.opacity)
    .padding(1)
    .disabled(true)
    .allowsHitTesting(false)
    .enableInjection()
  }
}

public final class FocusBorderPanel<Content>: NSPanel where Content: View {
  override public var canBecomeKey: Bool { false }
  override public var canBecomeMain: Bool { false }

  public init(animationBehavior: NSWindow.AnimationBehavior,
              contentRect: NSRect = .init(origin: .zero, size: .init(width: 200, height: 200)),
              styleMask: NSWindow.StyleMask = [.borderless, .nonactivatingPanel],
              content rootView: @autoclosure @escaping () -> Content)
  {
    super.init(contentRect: contentRect, styleMask: styleMask, backing: .buffered, defer: false)

    self.animationBehavior = animationBehavior
    collectionBehavior.insert(.fullScreenAuxiliary)
    collectionBehavior.insert(.canJoinAllSpaces)
    collectionBehavior.insert(.stationary)
    isOpaque = false
    isFloatingPanel = true
    isMovable = false
    isMovableByWindowBackground = false
    level = .screenSaver
    becomesKeyOnlyIfNeeded = false
    backgroundColor = .clear
    acceptsMouseMovedEvents = false
    hasShadow = false

    let rootView = rootView()
      .ignoresSafeArea()

    let contentViewController = NSHostingController(rootView: rootView)
    self.contentViewController = contentViewController
    setFrame(contentRect, display: false)
  }
}

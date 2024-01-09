import AXEssibility
import Bonzai
import Carbon
import Combine
import MachPort
import SwiftUI

@MainActor
final class UIElementCaptureStore: ObservableObject {
  private lazy var publisher = WindowBorderViewPublisher()
  private lazy var windowCoordinator: WindowCoordinator<WindowBordersView> = WindowCoordinator(
    .none,
    content: WindowBordersView(publisher: self.publisher)
  )

  @Published var isCapturing: Bool = false
  @Published var capturedElement: UIElementCaptureItem?
  private var modeSubscription: AnyCancellable?
  private var eventSubscription: AnyCancellable?
  private var flagsSubscription: AnyCancellable?

  private var coordinator: MachPortCoordinator?
  private var flags: CGEventFlags?

  #if DEBUG
  init(isCapturing: Bool = false,
       capturedElement: UIElementCaptureItem? = nil,
       modeSubscription: AnyCancellable? = nil,
       eventSubscription: AnyCancellable? = nil,
       flagsSubscription: AnyCancellable? = nil,
       coordinator: MachPortCoordinator? = nil,
       flags: CGEventFlags? = nil) {
    self.isCapturing = isCapturing
    self.capturedElement = capturedElement
    self.modeSubscription = modeSubscription
    self.eventSubscription = eventSubscription
    self.flagsSubscription = flagsSubscription
    self.coordinator = coordinator
    self.flags = flags
  }
  #endif

  func subscribe(to coordinator: MachPortCoordinator) {
    self.coordinator = coordinator
    modeSubscription = coordinator.$mode
      .dropFirst()
      .sink { [weak self] mode in
        guard let self else { return }
        switch mode {
        case .captureUIElement:
          isCapturing = true
          eventSubscription = coordinator.$event
            .dropFirst()
            .compactMap { $0 }
            .sink { [weak self] event in
              self?.handle(event)
            }
          flagsSubscription = coordinator.$flagsChanged
            .sink { [weak self] flags in
              self?.flags = flags
            }
        default:
          isCapturing = false
          eventSubscription = nil
        }
      }
  }

  func stopCapturing() {
    coordinator?.stopCapturingUIElement()
    UserModesBezelController.shared.hide()
    UserSpace.shared.userModesPublisher.publish([])
    publisher.publish([])
    windowCoordinator.close()
    capturedElement = nil
  }

  func toggleCapture() {
    if isCapturing {
      stopCapturing()
    } else {
      windowCoordinator.show()
      coordinator?.captureUIElement()
      UserSpace.shared.userModesPublisher.publish([
        .init(id: UUID().uuidString, name: "Capturing UI Element", isEnabled: true)
      ])
      UserModesBezelController.shared.show()
    }
  }

  private func handle(_ machPortEvent: MachPortEvent) {
    if machPortEvent.keyCode == kVK_Escape {
      stopCapturing()
    }

    guard let flags, flags != .maskNonCoalesced,
          var mouseLocation = CGEvent(source: nil)?.location else { return }
    if flags.contains(.maskCommand)  && isValidMouseEvent(machPortEvent.event) {
      machPortEvent.result = nil

      guard machPortEvent.type == .leftMouseUp else { return }

      let deltaX = machPortEvent.event.getDoubleValueField(.mouseEventDeltaX)
      let deltaY = machPortEvent.event.getDoubleValueField(.mouseEventDeltaY)
      mouseLocation.x -= deltaX
      mouseLocation.y -= deltaY
      let systemElement = SystemAccessibilityElement()
      guard let element = systemElement.element(at: mouseLocation, as: AnyAccessibilityElement.self),
            let frame = element.frame else {
        return
      }

      let id = UUID().uuidString
      let model: WindowBorderViewModel =  .init(id: id, frame: frame)
      publisher.publish([model])
      windowCoordinator.screenChanged()
      windowCoordinator.show()

      DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [publisher] in
        withAnimation {
          publisher.data.remove(model)
        }
      }

      let capturedElement = UIElementCaptureItem(
        description: element.description,
        identifier: element.identifier,
        title: element.title,
        value: element.value,
        role: element.role
      )
      self.capturedElement = capturedElement

      NSApp.activate(ignoringOtherApps: true)
    }
  }

  private func isValidMouseEvent(_ event: CGEvent) -> Bool {
    event.type == .leftMouseUp ||
    event.type == .leftMouseDown ||
    event.type == .leftMouseDragged
  }
}

struct UIElementCaptureItem {
  let description: String?
  let identifier: String?
  let title: String?
  let value: String?
  let role: String?
}

final class WindowBorderViewPublisher: ObservableObject {
  @Published var data: [WindowBorderViewModel] = []

  @MainActor
  func publish(_ data: [WindowBorderViewModel]) {
    self.data = data
  }
}

struct WindowBorderViewModel: Identifiable, Equatable {
  let id: String
  let frame: CGRect
}

struct WindowBordersView: View {
  @ObservedObject var publisher: WindowBorderViewPublisher
  @State var animateGradient: Bool = false
  private let lineWidth: CGFloat = 4

  var body: some View {
    ForEach(publisher.data) { model in
      RoundedRectangle(cornerRadius: 10)
        .stroke(Color.accentColor, lineWidth: lineWidth)
        .frame(width: model.frame.width - lineWidth / 2,
               height: model.frame.height - lineWidth / 2)
        .position(x: model.frame.midX,
                  y: model.frame.midY)
    }
    .onReceive(publisher.$data, perform: { newValue in
      withAnimation(.linear(duration: 1).repeatForever()) {
        animateGradient = !newValue.isEmpty
      }
    })
  }
}

@MainActor
final class WindowCoordinator<Content> where Content: View {
  private let controller: NSWindowController

  init(_ animationBehavior: NSWindow.AnimationBehavior, content: @escaping @autoclosure () -> Content) {
    let window = ZenPanel(
      animationBehavior: animationBehavior,
      contentRect: NSScreen.main!.frame,
      content: content()
    )
    let controller = NSWindowController(window: window)
    self.controller = controller
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(screenChanged),
      name: NSApplication.didChangeScreenParametersNotification,
      object: nil
    )
  }

  @objc func screenChanged() {
    guard let screenFrame = NSScreen.main?.frame else { return }
    self.controller.window?.setFrame(screenFrame, display: true)
  }

  func show() {
    controller.showWindow(nil)
    controller.window?.makeFirstResponder(nil)
  }

  func close() {
    controller.close()
  }
}

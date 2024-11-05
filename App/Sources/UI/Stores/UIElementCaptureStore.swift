import AXEssibility
import Bonzai
import Carbon
import Combine
import MachPort
import SwiftUI

@MainActor
final class UIElementCaptureStore: ObservableObject {
  private lazy var publisher = WindowBorderViewPublisher()
  private lazy var windowCoordinator: UIElementWindowCoordinator<WindowBordersView> = UIElementWindowCoordinator(
    .none,
    content: WindowBordersView(publisher: self.publisher)
  )

  @Published var isCapturing: Bool = false
  @Published var capturedElement: UIElementCaptureItem?
  private var modeSubscription: AnyCancellable?

  private var machPortController: MachPortEventController?
  private var coordinator: MachPortCoordinator?
  private var flags: CGEventFlags?

  private var restore: [Int32: Bool] = [:]

  #if DEBUG
  init(isCapturing: Bool = false,
       capturedElement: UIElementCaptureItem? = nil,
       flags: CGEventFlags? = nil) {
    self.isCapturing = isCapturing
    self.capturedElement = capturedElement
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
          let leftMouseEvents: CGEventMask = (1 << CGEventType.leftMouseDown.rawValue)
          | (1 << CGEventType.leftMouseUp.rawValue)
          | (1 << CGEventType.leftMouseDragged.rawValue)
          let keyboardEvents: CGEventMask = (1 << CGEventType.keyDown.rawValue)
          | (1 << CGEventType.keyUp.rawValue)
          | (1 << CGEventType.flagsChanged.rawValue)

          let newMachPortController = try? MachPortEventController(
            .privateState,
            eventsOfInterest: keyboardEvents | leftMouseEvents,
            signature: "com.zenangst.Keyboard-Cowboy",
            autoStartMode: .commonModes,
            onFlagsChanged: { [weak self] machPortEvent in
              self?.flags = machPortEvent.event.flags
            },
            onEventChange: { [weak self] event in
              self?.handle(event)
            })
          machPortController = newMachPortController
        default:
          isCapturing = false
          machPortController?.stop(mode: .commonModes)
          machPortController = nil
        }
      }
  }

  func stopCapturing() {
    coordinator?.stopCapturingUIElement()
    UserModeWindow.shared.show([])
    windowCoordinator.close()
    capturedElement = nil

    for (pid, value) in restore { AppAccessibilityElement(pid).enhancedUserInterface = value }
    restore.removeAll()
  }

  func toggleCapture() {
    if isCapturing {
      stopCapturing()
    } else {
      windowCoordinator.show()
      coordinator?.captureUIElement()
      UserModeWindow.shared.show([
        .init(id: UUID().uuidString, name: "Capturing UI Element", isEnabled: true)
      ])
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

      Task { @MainActor in
        let systemElement = SystemAccessibilityElement()
        guard let app = systemElement.element(at: mouseLocation, as: AppAccessibilityElement.self)?.app
        else { return }


        var enhancedUserInterface = false
        if let pid = app.pid, let appValue = app.enhancedUserInterface {
          let runningApplication = NSRunningApplication(processIdentifier: pid)
          runningApplication?.activate()
          try await Task.sleep(for: .milliseconds(100))

          app.enhancedUserInterface = true
          enhancedUserInterface = appValue
          AXUIElementSetAttributeValue(app.reference, "AXManualAccessibility" as CFString, true as CFTypeRef)
          if restore[pid] == nil {
            restore[pid] = enhancedUserInterface
          }
        }

        try await Task.sleep(for: .milliseconds(100))

        guard let element = systemElement.element(at: mouseLocation, as: AnyAccessibilityElement.self),
              let frame = element.frame else {
          app.enhancedUserInterface = enhancedUserInterface
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
final class UIElementWindowCoordinator<Content> where Content: View {
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

import Cocoa
import Carbon
import Combine
import SwiftUI

final class ResponderChain {
  private var responders = [Responder]()
  private var subscription: AnyCancellable?
  private var didBecomeActiveNotification: AnyCancellable?

  static public var shared: ResponderChain = .init()

  @Environment(\.scenePhase) private var scenePhase

  @AppStorage("responderId") var responderId: String = ""

  private init() {
    guard !responderId.isEmpty else { return }

    let initialResponderId = responderId
    didBecomeActiveNotification = NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
      .sink { [weak self] value in
        guard let self = self else { return }
        self.makeFirstResponder(initialResponderId)
        self.didBecomeActiveNotification = nil
      }
  }

  func resetSelection() {
    responders.forEach { $0.isSelected = false }
  }

  func extendSelection(_ responder: Responder) {
    guard let lhs = responders.firstIndex(where: { $0.id == responderId }),
          let rhs = responders.firstIndex(where: { $0.id == responder.id }) else {
      return
    }

    let slice: ArraySlice<Responder>

    responder.isSelected.toggle()

    guard lhs != rhs else {
      return
    }

    if lhs > rhs {
      slice = responders[rhs...lhs]
    } else {
      slice = responders[lhs...rhs]
    }

    slice.forEach { $0.isSelected = responder.isSelected }
  }

  func makeFirstResponder(_ id: String) {
    guard let responder = responders.first(where: { $0.id == id }) else { return }
    subscription = responder.$makeFirstResponder
      .compactMap { $0 }
      .receive(on: RunLoop.main)
      .sink(receiveValue: { [weak self] completion in
        completion(false)
        self?.subscription = nil
        self?.responderId = id
      })
  }

  func setPreviousResponder(_ currentResponder: Responder) {
    if let index = responders.firstIndex(where: { $0.id == currentResponder.id }),
       index >= 1 {
      makeFirstResponder(responders[index - 1].id)
    }
  }

  func setNextResponder(_ currentResponder: Responder) {
    if let index = responders.firstIndex(where: { $0.id == currentResponder.id }),
       index < responders.count - 1 {
      makeFirstResponder(responders[index + 1].id)
    }
  }

  func clean() {
    responders.removeAll(where: { $0.view == nil })
  }

  func remove(_ responder: Responder) {
    responders.removeAll(where: { $0.id == responder.id })
  }

  func add(_ responder: Responder) {
    clean()
    responders.append(responder)
  }
}

final class Responder: ObservableObject {
  let id: String
  @Published var isFirstReponder: Bool
  @Published var isHovering: Bool
  @Published var isSelected: Bool
  @Published var makeFirstResponder: ((Bool) -> Void)?
  weak var view: NSView?

  init(_ id: String = UUID().uuidString) {
    self.id = id
    _isFirstReponder = .init(initialValue: false)
    _isHovering = .init(initialValue: false)
    _isSelected = .init(initialValue: false)
  }
}

struct ResponderView<Content>: View where Content: View {
  @StateObject var responder: Responder
  let content: (Responder) -> Content

  init<T: Identifiable>(_ identifiable: T,
                        content: @escaping (Responder) -> Content) where T.ID == String {
    _responder = .init(wrappedValue: .init(identifiable.id))
    self.content = content
  }

  init(_ id: String = UUID().uuidString,
       content: @escaping (Responder) -> Content) {
    _responder = .init(wrappedValue: .init(id))
    self.content = content
  }

  var body: some View {
    ZStack {
      ResponderRepresentable(responder: responder)
      content(responder)
        .onHover {
          responder.isHovering = $0
        }
        .gesture(TapGesture().modifiers(.shift).onEnded({ value in
          responder.makeFirstResponder?(true)
        }))
        .onTapGesture {
          responder.makeFirstResponder?(false)
        }
    }
  }
}

private struct ResponderRepresentable: NSViewRepresentable {
  @StateObject var responder: Responder

  func makeNSView(context: Context) -> FocusNSView {
    let view = FocusNSView(responder)
    responder.view = view
    ResponderChain.shared.add(responder)
    return view
  }

  func updateNSView(_ nsView: Self.NSViewType, context: Context) { }
}

private final class FocusNSView: NSControl {
  override var canBecomeKeyView: Bool { true }
  override var acceptsFirstResponder: Bool { true }

  private let responder: Responder
  private var firstResponderSubscription: AnyCancellable?
  private var windowSubscription: AnyCancellable?

  fileprivate init(_ responder: Responder) {
    self.responder = responder
    super.init(frame: .zero)

    windowSubscription = publisher(for: \.window)
      .compactMap { $0 }
      .sink { [weak self] window in
        self?.subscribe(to: window)
      }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func keyDown(with event: NSEvent) {
    super.keyDown(with: event)

    switch Int(event.keyCode) {
    case kVK_DownArrow:
      ResponderChain.shared.setNextResponder(responder)
    case kVK_UpArrow:
      ResponderChain.shared.setPreviousResponder(responder)
    default:
      break
    }
  }

  fileprivate func subscribe(to window: NSWindow) {
    firstResponderSubscription = window.publisher(for: \.firstResponder)
      .sink { [responder, weak self] firstResponder in
        guard let self = self else { return }
        responder.isFirstReponder = firstResponder == self
      }

    responder.makeFirstResponder = { [weak self] isSelected in
      guard let self = self else { return }
      if isSelected {
        ResponderChain.shared.extendSelection(self.responder)
      } else {
        ResponderChain.shared.resetSelection()
      }
      window.makeFirstResponder(self)
      ResponderChain.shared.responderId = self.responder.id
    }
  }
}

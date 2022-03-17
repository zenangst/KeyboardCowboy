import Cocoa
import Carbon
import Combine
import SwiftUI

final class ResponderChain: ObservableObject {
  @Published private(set) var responders = [Responder]()
  private var subscription: AnyCancellable?
  private var didBecomeActiveNotification: AnyCancellable?
  private var didResizeNotification: AnyCancellable?

  static public var shared: ResponderChain = .init()

  @Environment(\.scenePhase) private var scenePhase

  @AppStorage("responderId") var responderId: String = ""

  private init() {
    guard !responderId.isEmpty else { return }

    let initialResponderId = responderId
    didBecomeActiveNotification = NotificationCenter.default
      .publisher(for: NSApplication.didBecomeActiveNotification)
      .sink { [weak self] value in
        guard let self = self else { return }
        self.makeFirstResponder(initialResponderId)
        self.didBecomeActiveNotification = nil
      }

    didResizeNotification = NotificationCenter.default
      .publisher(for: NSWindow.didResizeNotification)
      .debounce(for: 0.375, scheduler: RunLoop.main)
      .sink(receiveValue: { [weak self] _ in
        self?.sort()
      })
  }

  func resetSelection() {
    responders.forEach { $0.isSelected = false }
  }

  func select(_ responders: [Responder]) {
    responders.forEach { $0.isSelected = true }
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

  func selectNamespace(_ namespace: Namespace.ID) {
    let namedSpaceResponders = self.responders.filter({ $0.namespace == namespace })
    let selectedResponders = namedSpaceResponders.filter({ $0.isSelected == true })

    if namedSpaceResponders.count == selectedResponders.count {
      namedSpaceResponders.forEach({ $0.isSelected.toggle() })
    } else {
      namedSpaceResponders.forEach({ $0.isSelected = true })
    }
  }

  func makeFirstResponder<T: Identifiable>(_ identifiable: T) where T.ID == String {
    makeFirstResponder(identifiable.id)
  }

  func makeFirstResponder(_ id: String) {
    guard let responder = responders.first(where: { $0.id == id }) else { return }

    if let view = responder.view,
      let scrollView = view.findSuperview(NSScrollView.self) {
      var documentVisibleRect = scrollView.documentVisibleRect
      documentVisibleRect.origin.y += scrollView.contentInsets.top * 2
      documentVisibleRect.size.height -= scrollView.contentInsets.top * 2

      let convertedFrame = view.convert(view.bounds, to: scrollView)

      if !convertedFrame.intersects(documentVisibleRect) {
        var newRect = scrollView.contentView.documentVisibleRect
        newRect.origin.y = convertedFrame.origin.y
        scrollView.contentView.scroll(newRect.origin)
      }
    }

    subscription = responder.$makeFirstResponder
      .compactMap { $0 }
      .sink(receiveValue: { [weak self] completion in
        completion(.none)
        self?.subscription = nil
        self?.responderId = id
      })
  }

  func resignFirstResponder(_ responder: Responder) {
    responder.view?.window?.resignFirstResponder()
    responder.isFirstReponder = false
  }

  func setPreviousResponder(_ currentResponder: Responder) {
    guard let view = currentResponder.view else { return }

    let currentNamespaceResponders = responders
      .filter({
        $0.id != currentResponder.id &&
        $0.namespace == currentResponder.namespace &&
        $0.view != nil
      })
      .sorted(by: { $0.view?.frameInWindow().origin.x ?? 0 < $1.view?.frameInWindow().origin.x ?? 0 })
      .sorted(by: { $0.view?.frameInWindow().origin.y ?? 0 < $1.view?.frameInWindow().origin.y ?? 0 })

    let responderFrame = view.frameInWindow()

    if let next = currentNamespaceResponders
      .last(where: { responder in
        guard let nextView = responder.view else {
          return false
        }
        let nextResponderFrame = nextView.frameInWindow()

        return nextResponderFrame.origin.y < responderFrame.origin.y ||
        nextResponderFrame.origin.x < responderFrame.origin.x
      }) {
      makeFirstResponder(next.id)
    }
  }

  func setNextResponder(_ currentResponder: Responder) {
    guard let view = currentResponder.view else { return }

    let currentNamespaceResponders = responders
      .filter({
        $0.namespace == currentResponder.namespace &&
        $0.view != nil
      })
    let responderFrame = view.frameInWindow()

    if let next = currentNamespaceResponders
      .first(where: { responder in
        guard let nextView = responder.view else {
          return false
        }
        let nextResponderFrame = nextView.frameInWindow()

        return nextResponderFrame.origin.x > responderFrame.origin.x ||
        nextResponderFrame.origin.y > responderFrame.origin.y 

      }) {
      makeFirstResponder(next.id)
    }
  }

  func clean() {
    responders.removeAll(where: { $0.view == nil })
  }

  func sort() {
    responders
      .sort(by: { lhs, rhs in
        guard let leftView = lhs.view, let rightView = rhs.view else { return false }
        return leftView.frameInWindow().origin.y < rightView.frameInWindow().origin.y
      })
  }

  func remove(_ responder: Responder) {
    responders.removeAll(where: { $0.id == responder.id })
  }

  func add(_ responder: Responder) {
    clean()
    if let firstIndex = responders.firstIndex(where: { $0.id == responder.id }) {
      responders[firstIndex] = responder
    } else {
      responders.append(responder)
    }
  }
}

final class Responder: ObservableObject {
  enum Modifier {
    case shift, command
  }
  weak var view: NSView?

  let id: String
  var namespace: Namespace.ID?
  var isHighlighted: Bool { isFirstReponder || isSelected }

  @Published var isFirstReponder: Bool
  @Published var isHovering: Bool
  @Published var isSelected: Bool
  @Published var makeFirstResponder: ((Modifier?) -> Void)?



  init(_ id: String = UUID().uuidString, namespace: Namespace.ID? = nil) {
    self.id = id
    self.namespace = namespace
    _isFirstReponder = .init(initialValue: false)
    _isHovering = .init(initialValue: false)
    _isSelected = .init(initialValue: false)
  }
}

enum ResponderAction {
  case enter
}

struct ResponderView<Content>: View where Content: View {
  typealias ResponderHandler = (ResponderAction) -> Void
  @StateObject var responder: Responder
  let content: (Responder) -> Content
  let action: ResponderHandler?
  let onDoubleClick: (() -> Void)?

  init<T: Identifiable>(_ identifiable: T,
                        namespace: Namespace.ID? = nil,
                        action: ResponderHandler? = nil,
                        onDoubleClick: (() -> Void)? = nil,
                        content: @escaping (Responder) -> Content) where T.ID == String {
    _responder = .init(wrappedValue: .init(identifiable.id, namespace: namespace))
    self.content = content
    self.action = action
    self.onDoubleClick = onDoubleClick
  }

  init(_ id: String = UUID().uuidString,
       namespace: Namespace.ID? = nil,
       action: ResponderHandler? = nil,
       onDoubleClick: (() -> Void)? = nil,
       content: @escaping (Responder) -> Content) {
    _responder = .init(wrappedValue: .init(id, namespace: namespace))
    self.content = content
    self.action = action
    self.onDoubleClick = onDoubleClick
  }

  var body: some View {
    ZStack {
      ResponderRepresentable(responder) { action in
        self.action?(action)
      }
      content(responder)
        .onHover { responder.isHovering = $0 }
        .gesture(
          TapGesture().modifiers(.shift).onEnded {
            responder.makeFirstResponder?(.shift)
          }
        )
        .gesture(
          TapGesture().modifiers(.command).onEnded {
            responder.makeFirstResponder?(.command)
          }
        )
        .gesture(
          TapGesture(count: 1).onEnded({
            responder.makeFirstResponder?(.none)
          }).simultaneously(with: TapGesture(count: 2).onEnded({
            onDoubleClick?()
          }))
        )
    }
  }
}

struct ResponderBackgroundView: View {
  @StateObject var responder: Responder

  var cornerRadius: CGFloat = 8

  @ViewBuilder
  var body: some View {
    RoundedRectangle(cornerRadius: cornerRadius)
      .stroke(Color.accentColor.opacity(responder.isFirstReponder ?
                                        responder.isSelected ? 1.0 : 0.5 : 0.0))
      .opacity(responder.isFirstReponder ? 1.0 : 0.05)

    RoundedRectangle(cornerRadius: cornerRadius)
      .fill(Color.accentColor.opacity((responder.isFirstReponder || responder.isSelected) ? 0.5 : 0.0))
      .opacity((responder.isFirstReponder || responder.isSelected) ? 1.0 : 0.05)
  }
}

private struct ResponderRepresentable: NSViewRepresentable {
  @StateObject var responder: Responder
  private var action: (ResponderAction) -> Void

  init(_ responder: Responder, action: @escaping (ResponderAction) -> Void) {
    _responder = .init(wrappedValue: responder)
    self.action = action
  }

  func makeNSView(context: Context) -> FocusNSView {
    let view = FocusNSView(responder, action: action)
    responder.view = view
    ResponderChain.shared.add(responder)
    return view
  }

  func updateNSView(_ nsView: Self.NSViewType, context: Context) {
    responder.view = nsView
  }
}

private final class FocusNSView: NSControl {
  override var canBecomeKeyView: Bool { true }
  override var acceptsFirstResponder: Bool { true }

  private let chain: ResponderChain
  private let responder: Responder
  private var firstResponderSubscription: AnyCancellable?
  private var windowSubscription: AnyCancellable?
  private var actionHandler: (ResponderAction) -> Void

  fileprivate init(_ responder: Responder,
                   responderChain: ResponderChain = .shared,
                   action: @escaping (ResponderAction) -> Void) {
    self.chain = responderChain
    self.responder = responder
    self.actionHandler = action
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
    case kVK_ANSI_A:
      guard let namespace = responder.namespace,
            event.modifierFlags.contains(.command) else { return }
      chain.selectNamespace(namespace)
    case kVK_Escape:
      let shouldResignFirstResponder = chain.responders.filter({ $0.isSelected }).isEmpty
      chain.resetSelection()
      guard shouldResignFirstResponder else { return }
      chain.resignFirstResponder(responder)
    case kVK_DownArrow, kVK_RightArrow:
      let selectedResponders = chain.responders.filter({ $0.isFirstReponder || $0.isSelected })
      chain.setNextResponder(responder)
      if event.modifierFlags.contains(.shift) {
        chain.select(selectedResponders)
      }
    case kVK_UpArrow, kVK_LeftArrow:
      let selectedResponders = chain.responders.filter({ $0.isFirstReponder || $0.isSelected })
      chain.setPreviousResponder(responder)
      if event.modifierFlags.contains(.shift) {
        chain.select(selectedResponders)
      }
    case kVK_Return:
      actionHandler(.enter)
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

    responder.makeFirstResponder = { [weak self, chain, responder] modifier in
      guard let self = self else { return }
      switch modifier {
      case .shift:
        chain.extendSelection(responder)
      case .command:
        guard let selectedNamespace = responder.namespace else { return }

        let responders = chain.responders
          .filter({ $0.namespace == selectedNamespace })

        if !responders.filter({ $0.isFirstReponder }).isEmpty {
          responder.isSelected.toggle()
          return
        }
      case .none:
        chain.resetSelection()
      }

      window.makeFirstResponder(self)
      chain.responderId = responder.id
    }
  }
}

fileprivate extension Sequence where Iterator.Element: Hashable {
    func unique() -> [Iterator.Element] {
        var seen: [Iterator.Element: Bool] = [:]
        return self.filter { seen.updateValue(true, forKey: $0) == nil }
    }
}

fileprivate extension NSView {
  func frameInWindow() -> NSRect {
    convert(bounds, to: window?.contentView)
  }
}

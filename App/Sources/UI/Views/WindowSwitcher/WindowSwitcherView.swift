import Apps
import AXEssibility
import Bonzai
import Cocoa
import HotSwiftUI
import SwiftUI

@MainActor
final class WindowSwitcherPublisher: ObservableObject {
  @Published var items: [WindowSwitcherView.Item] = []
  @Published var selections: Set<WindowSwitcherView.Item.ID> = []
  @Published var modifiers: NSEvent.ModifierFlags = []
  @Published var query: String = ""

  init(items: [WindowSwitcherView.Item], selections: [WindowSwitcherView.Item.ID]) {
    self.items = items
    self.selections = Set(selections)
  }

  func publish(_ items: [WindowSwitcherView.Item]) {
    self.items = items
  }

  func publish(_ selections: [WindowSwitcherView.Item.ID]) {
    self.selections = Set(selections)
  }
}

struct WindowSwitcherView: View {
  struct Item: Identifiable, Equatable {
    enum Kind: Equatable {
      case application
      case window(window: WindowAccessibilityElement, onScreen: Bool)

      static func == (lhs: Kind, rhs: Kind) -> Bool {
        switch (lhs, rhs) {
        case (.application, .application):
          true
        case (.window, .window):
          true
        default:
          false
        }
      }
    }

    let id: String
    let title: String
    let app: Application
    let kind: Kind
    let hints: Hints

    struct Hints {
      let commandKey: String
    }

    var onScreen: Bool {
      switch kind {
      case .application: true
      case let .window(_, onScreen): onScreen == true
      }
    }

    var isMinimized: Bool {
      switch kind {
      case .application: false
      case let .window(window, _):
        window.isMinimized == true
      }
    }

    static func == (lhs: Item, rhs: Item) -> Bool {
      lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.kind == rhs.kind
    }
  }

  enum Focus: Hashable {
    case textField
  }

  @FocusState var focus: Focus?
  @ObserveInjection var inject
  @ObservedObject private var publisher: WindowSwitcherPublisher

  init(publisher: WindowSwitcherPublisher) {
    self.publisher = publisher
    focus = .textField
  }

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        TextField(text: $publisher.query, label: {
          Text(publisher.query)
        })
        .environment(\.textFieldFont, .largeTitle)
        .environment(\.textFieldGlow, false)
        .environment(\.textFieldDecorationColor, .clear)
        .environment(\.textFieldFocusEffect, false)
        .environment(\.textFieldHoverEffect, false)
        .environment(\.textFieldGrayscaleEffect, false)
        .overlay(alignment: .leading) {
          PromptView(publisher: publisher)
        }
        if let match = publisher.items.first(where: { publisher.selections.contains($0.id) }) {
          IconView(icon: Icon(match.app),
                   size: CGSize(width: 32, height: 32))
        }
      }
      .padding(.horizontal, 8)
      .padding(.top, 4)
      .focused($focus, equals: .textField)

      ZenDivider()

      ScrollViewReader { proxy in
        CompatList {
          ForEach(publisher.items) { item in
            HStack(spacing: 4) {
              WindowView(item, selected: Binding<Bool>.readonly { publisher.selections.contains(item.id) })
            }
            .contentShape(RoundedRectangle(cornerRadius: 8))
            .compositingGroup()
            .onTapGesture {
              publisher.selections.removeAll()
              publisher.selections.insert(item.id)
            }
          }
        }
        .animation(.linear, value: publisher.items)
        .onChange(of: publisher.query) { newValue in
          if newValue.isEmpty {
            proxy.scrollTo(publisher.selections.first)
          }
        }
        .onChange(of: publisher.selections, perform: { newValue in
          proxy.scrollTo(newValue.first)
          focus = .textField
        })
        .overlay(alignment: .bottomLeading) {
          if let id = publisher.selections.first,
             let selected = publisher.items.first(where: { $0.id == id }) {
            Text(selected.hints.commandKey)
              .font(.caption)
              .padding(4)
              .background()
              .clipShape(RoundedRectangle(cornerRadius: 4))
              .padding(.leading, 6)
              .padding(.bottom, 4)
              .opacity(publisher.modifiers.contains(.command) ? 1 : 0)
              .animation(.smooth, value: publisher.modifiers)
          }
        }
      }
    }
    .onAppear {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        focus = .textField
      }
    }
    .background(ZenVisualEffectView(material: .headerView, blendingMode: .behindWindow, state: .active))
    .ignoresSafeArea()
    .enableInjection()
  }
}

private struct PromptView: View {
  @ObserveInjection var inject
  @ObservedObject private var publisher: WindowSwitcherPublisher
  @State var prompt = ""
  @State private var textSize: CGSize = .zero

  init(publisher: WindowSwitcherPublisher) {
    self.publisher = publisher
  }

  var body: some View {
    ZStack {
      Text(prompt)
        .allowsHitTesting(false)
        .lineLimit(1)
        .foregroundStyle(.secondary)
        .onChange(of: publisher.selections, perform: { _ in
          if let match = publisher.items.first(where: { publisher.selections.contains($0.id) }) {
            switch match.kind {
            case .application:
              prompt = "Open \(match.app.displayName)"
            case let .window(window, _):
              if let title = window.title {
                prompt = "Switch to \(title)"
              } else {
                prompt = "Switch to \(match.app.displayName)"
              }
            }
          }
        })
        .offset(x: textSize.width + (publisher.query.isEmpty ? 12 : 18))

      Text(publisher.query)
        .font(.largeTitle)
        .background(GeometryReader { geometry in
          Color.clear
            .onAppear {
              textSize = geometry.size
            }
            .onChange(of: geometry.size) { newSize in
              textSize = newSize
            }
        })
        .opacity(0)
    }
    .enableInjection()
  }
}

private struct WindowView: View {
  @ObserveInjection var inject
  private let item: WindowSwitcherView.Item
  private var selected: Binding<Bool>
  @State private var animated: Bool = false

  init(_ item: WindowSwitcherView.Item, selected: Binding<Bool>) {
    self.item = item
    self.selected = selected
  }

  var body: some View {
    HStack {
      IconView(icon: Icon(item.app),
               size: CGSize(width: 32, height: 32))
        .opacity(item.onScreen ? 1 : item.isMinimized == true ? 1 : 0.5)
        .overlay(alignment: .bottomTrailing) {
          Image(systemName: "arrow.down.app.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 16, height: 16)
            .foregroundStyle(Color.white)
            .shadow(radius: 2)
            .opacity(item.isMinimized == true ? 1 : 0)
        }
      Text(item.title)
        .font(.title3)
        .lineLimit(1)
        .minimumScaleFactor(0.9)
      Spacer()
      Text(item.app.displayName)
        .foregroundStyle(Color.secondary)
        .padding(.trailing, 4)
        .font(.caption)
    }
    .shadow(radius: 1, y: 1)
    .padding(.vertical, 2)
    .padding(.horizontal, 4)
    .background {
      LinearGradient(stops: [
        Gradient.Stop(color: Color.accentColor
          .opacity(selected.wrappedValue ? 0.5 : 0), location: 0.0),
        Gradient.Stop(color: Color.clear, location: 1.0),
      ], startPoint: .top, endPoint: .bottom)
        .mask {
          RoundedRectangle(cornerRadius: 6)
        }
    }
    .overlay {
      RoundedRectangle(cornerRadius: 6)
        .stroke(
          LinearGradient(
            stops: gradientColorStops(for: selected.wrappedValue),
            startPoint: .top,
            endPoint: .bottom,
          ), lineWidth: 1,
        )
        .padding(1)
        .opacity(selected.wrappedValue ? 1 : 0)
    }
    .onAppear {
      if selected.wrappedValue {
        withAnimation(.smooth) {
          animated = true
        }
      }
    }
    .enableInjection()
  }

  private func gradientColorStops(for selected: Bool) -> [Gradient.Stop] {
    if selected, animated {
      [
        Gradient.Stop(color: Color(nsColor: .controlAccentColor.withSystemEffect(.pressed)).opacity(0.9), location: 0.0),
        Gradient.Stop(color: Color.white.opacity(0.3), location: 1.0),
      ]
    } else {
      [
        Gradient.Stop(color: Color.white.opacity(0.3), location: 0.0),
        Gradient.Stop(color: Color(nsColor: .controlAccentColor.withSystemEffect(.pressed)).opacity(0.9), location: 1.0),
      ]
    }
  }
}

//
// #Preview {
//  let publisher = WindowSwitcherPublisher(items: [
//    WindowSwitcherView.Item(id: "1", title: "~", app: .finder()),
//    WindowSwitcherView.Item(id: "2", title: "Work", app: .calendar()),
//    WindowSwitcherView.Item(id: "3", title: "~", app: .systemSettings()),
//  ], selections: ["1"])
//  return WindowSwitcherView(publisher: publisher)
// }

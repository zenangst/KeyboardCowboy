import Apps
import Inject
import Bonzai
import SwiftUI

@MainActor
struct NewCommandMenuBarView: View {
  struct TokenContainer: Identifiable, Hashable {
    let id = UUID()
    var token: MenuBarCommand.Token
  }

  enum Kind: String, CaseIterable, Hashable, Identifiable {
    var id: String { self.rawValue }
    case menuItem = "Select menu"
    case menuItems = "Toggle menu"
  }

  enum Focus: Hashable {
    case token(MenuBarCommand.Token)
    case add
  }

  private let wikiUrl = URL(string: "https://github.com/zenangst/KeyboardCowboy/wiki/Commands#menu-bar-commands")!

  @Namespace var namespace
  @FocusState var focus: Focus?
  @Environment(\.resetFocus) var resetFocus
  @EnvironmentObject var applicationStore: ApplicationStore

  @Binding private var payload: NewCommandPayload
  @Binding private var validation: NewCommandValidation

  @State private var kind: Kind
  @State private var tokens = [TokenContainer]()

  @State private var menuItem: String = ""
  @State private var menuItems: (String, String) = ("","")
  @State private var application: Application?

  init(_ payload: Binding<NewCommandPayload>,
       validation: Binding<NewCommandValidation>,
       kind: Kind = .menuItem) {
    _payload = payload
    _validation = validation
    _kind = .init(initialValue: kind)

    if case .menuBar(let tokens, let application) = payload.wrappedValue {
      _tokens = .init(initialValue: tokens.map(TokenContainer.init))
      _application = .init(initialValue: application)
    } else {
      _tokens = .init(initialValue: [])
    }
  }

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        ZenLabel("Menu Bar item:")
        Spacer()
        Button(action: { NSWorkspace.shared.open(wikiUrl) },
               label: { Image(systemName: "questionmark.circle.fill") })
      }
      VStack {
        ScrollView {
          ForEach(tokens) { container in
            HStack {
              switch container.token {
              case .menuItem(let value):
                NewCommandMenuBarTokenMenuItemView(value: Binding(get: { value }, set: {
                  var container = container
                  container.token = .menuItem(name: $0)
                  tokens.replace(container)
                  validation = updateAndValidatePayload()
                }), onSubmit: {})
              case .menuItems(let lhs, let rhs):
                NewCommandMenuBarTokenMenuItemsView(lhs: Binding(get: { lhs }, set: {
                  var container = container
                  container.token = .menuItems(name: $0, fallbackName: rhs)
                  tokens.replace(container)
                  validation = updateAndValidatePayload()
                }),
                                                 rhs: Binding(get: { rhs }, set: {
                  var container = container
                  container.token = .menuItems(name: lhs, fallbackName: $0)
                  tokens.replace(container)
                  validation = updateAndValidatePayload()
                }), onSubmit: {})
              }
              Spacer()
              Button(action: {
                withAnimation {
                  tokens.remove(container)
                  validation = updateAndValidatePayload()
                }
              }, label: {
                Image(systemName: "xmark")
                  .resizable()
                  .aspectRatio(contentMode: .fill)
                  .frame(width: 8, height: 10)
              })
              .buttonStyle(.destructive)
            }
          }
          .roundedSubStyle(padding: 8)
          .frame(maxWidth: .infinity, alignment: .topLeading)
          overlay()
            .padding(.top, 8)
        }
        if !tokens.isEmpty {
          ZenDivider()
          addView()
            .roundedSubStyle(padding: 8)
            .matchedGeometryEffect(id: "add-buttons", in: namespace)
        }
      }
    }
    .onChange(of: validation, perform: { newValue in
      guard newValue == .needsValidation else { return }
      withAnimation { validation = updateAndValidatePayload() }
    })
    .onAppear {
      if tokens.isEmpty {
        validation = .unknown
      } else {
        validation = updateAndValidatePayload()
      }
    }
    .focusScope(namespace)
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  @discardableResult
  private func updateAndValidatePayload() -> NewCommandValidation {
    guard !tokens.isEmpty else { return .invalid(reason: "You need to add at least one menu item.") }

    payload = .menuBar(tokens: tokens.map { $0.token }, application: application)

    return .valid
  }

  @ViewBuilder
  func overlay() -> some View {
    if tokens.isEmpty {
      VStack {
        addView()
          .roundedSubStyle(padding: 8)
          .matchedGeometryEffect(id: "add-buttons", in: namespace)
      }
      ZenDivider()
      Text("Enter the exact name of the menu command you want to add.")
        .allowsHitTesting(false)
        .roundedStyle()
    }
  }

  func addView() -> some View {
    HStack {
      MenuIconView(size: 24)

      switch kind {
      case .menuItem:
        NewCommandMenuBarTokenMenuItemView(value: $menuItem, onSubmit: { onSubmit() })
          .focused($focus, equals: .add)
      case .menuItems:
        NewCommandMenuBarTokenMenuItemsView(lhs: Binding(get: { menuItems.0 }, set: { menuItems.0 = $0 }),
                                         rhs: Binding(get: { menuItems.1 }, set: { menuItems.1 = $0 }),
                                            onSubmit: { onSubmit() })
        .focused($focus, equals: .add)
      }

      Menu {
        ForEach(Kind.allCases) { kind in
          Button(kind.rawValue, action: {
            self.kind = kind
          })
        }
      } label: {
        Text(kind.rawValue)
      }
      .fixedSize()

      Button(action: { onSubmit() }, label: { Text("Add") })
    }
  }

  func onSubmit() {
    withAnimation {
      switch kind {
      case .menuItem:
        guard !menuItem.isEmpty else { return }
        tokens.append(.init(token: .menuItem(name: menuItem)))
        menuItem = ""
      case .menuItems:
        guard !menuItems.0.isEmpty && !menuItems.1.isEmpty else { return }
        tokens.append(.init(token: .menuItems(name: menuItems.0, fallbackName: menuItems.1)))
        menuItems = ("", "")
      }

      validation = updateAndValidatePayload()

      DispatchQueue.main.async {
        focus = .add
        resetFocus.callAsFunction(in: namespace)
      }
    }
  }
}

private struct NewCommandMenuBarTokenMenuItemView: View {
  @Binding var value: String
  var onSubmit: () -> Void

  var body: some View {
    TextField("Menu item", text: $value)
      .onSubmit(onSubmit)
  }
}

private struct NewCommandMenuBarTokenMenuItemsView: View {
  enum Focus: Hashable {
    case lhs, rhs
  }
  @Namespace var namespace
  @FocusState var focus: Focus?
  @Binding var lhs: String
  @Binding var rhs: String

  var onSubmit: () -> Void

  var body: some View {
    HStack {
      Text("Either:")
      TextField("", text: $lhs)
        .onSubmit {
          focus = .rhs
        }
        .focused($focus, equals: .lhs)
      Text(" or ")
      TextField("", text: $rhs)
        .focused($focus, equals: .rhs)
        .onSubmit(onSubmit)
    }
    .focusScope(namespace)
  }
}

struct NewCommandMenuBarView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      NewCommandView(
        workflowId: UUID().uuidString,
        commandId: nil,
        title: "New command",
        selection: .menuBar,
        payload: .placeholder,
        onDismiss: {},
        onSave: { _, _ in })
      .previewDisplayName("Empty")


      NewCommandView(
        workflowId: UUID().uuidString,
        commandId: nil,
        title: "New command",
        selection: .menuBar,
        payload: .menuBar(tokens: [
          .menuItem(name: "View"),
          .menuItem(name: "Navigators"),
          .menuItems(name: "Show Navigator", fallbackName: "Hide Navigator")
        ], application: nil),
        onDismiss: {},
        onSave: { _, _ in })
      .previewDisplayName("With instructions")
    }
    .designTime()
  }
}


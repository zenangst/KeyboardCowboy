import SwiftUI

struct ConfigurationSidebarView: View {
  @FocusState var focus: Focus?
  @ObserveInjection var inject
  @ObservedObject var contentStore: ContentStore
  @ObservedObject var store: ConfigurationStore
  @State var presentingPopover: Bool = false
  @State var presentingSheet: Bool = false

  init(_ store: ConfigurationStore,
       contentStore: ContentStore,
       focus: FocusState<Focus?>) {
    _store = .init(initialValue: store)
    _contentStore = .init(initialValue: contentStore)
    _focus = focus
  }

  var body: some View {
    Button(action: {
      withAnimation(.interactiveSpring()) { presentingPopover.toggle() }
    }) {
      HStack {
        Text(store.selectedConfiguration.name)
          .lineLimit(1)
        Spacer()
        Divider()
        Image(systemName: "chevron.down")
          .rotationEffect(presentingPopover ? .degrees(180) : .zero)
      }
      .fixedSize(horizontal: false, vertical: true)
      .allowsTightening(true)
    }
    .popover(isPresented: $presentingPopover, arrowEdge: .bottom) {
      ConfigurationPopoverView(focus: _focus, store: store) { action in
        switch action {
        case .edit:
          presentingSheet = true
        case .newConfiguration:
          store.add(.empty())
        case .remove(let configuration):
          store.remove(configuration)
        case .select(let configuration):
          store.select(configuration)
          contentStore.use(configuration)
          withAnimation {
            presentingPopover.toggle()
          }
        }
      }
      .frame(minWidth: 250, minHeight: 250)
    }
    .sheet(isPresented: $presentingSheet) {
      EditConfigurationView(store) { action in
        switch action {
        case .ok(let configuration):
          store.update(configuration)
          withAnimation {
            presentingSheet = false
          }
        case .cancel:
          presentingSheet = false
        }
      }
      .frame(minWidth: 480)
    }
    .transform(KCButtonStyle.modifiers) // Use the modifiers to not break keyboard shortcuts
    .keyboardShortcut(.init("T"), modifiers: .command)
    .enableInjection()
  }
}

struct ConfigurationSidebarView_Previews: PreviewProvider {
  static var previews: some View {
    VStack {
      ConfigurationSidebarView(configurationStore,
                               contentStore: contentStore,
                               focus: FocusState<Focus?>())
    }
    .padding()
    .previewLayout(.fixed(width: 380, height: 100))
  }
}

import SwiftUI

struct ConfigurationSidebarView: View {
  @FocusState var focus: Focus?
  @ObservedObject var saloon: Saloon
  @ObservedObject var store: ConfigurationStore
  @State var presentingPopover: Bool = false
  @State var presentingSheet: Bool = false

  init(_ store: ConfigurationStore,
       focus: FocusState<Focus?>,
       saloon: Saloon) {
    _store = .init(initialValue: store)
    _saloon = .init(initialValue: saloon)
    _focus = focus
  }

  var body: some View {
    Button(action: {
      withAnimation(.interactiveSpring()) { presentingPopover.toggle() }
    }) {
      HStack {
        Text(store.selectedConfiguration.name)
        Spacer()
        Divider()
        Image(systemName: "chevron.down")
          .rotationEffect(presentingPopover ? .degrees(180) : .zero)
      }
      .fixedSize(horizontal: false, vertical: true)
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
          saloon.use(configuration)
          withAnimation {
            presentingPopover.toggle()
          }
        }
      }
      .frame(minWidth: 250, minHeight: 250)
    }
    .sheet(isPresented: $presentingSheet) {
      ConfigurationView(store) { action in
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
    .keyboardShortcut(.init("T"), modifiers: .command)
    .padding(6)
    .background(
      RoundedRectangle(cornerRadius: 4)
        .stroke(Color(.controlColor))
    )
    .buttonStyle(BorderlessButtonStyle())
  }
}

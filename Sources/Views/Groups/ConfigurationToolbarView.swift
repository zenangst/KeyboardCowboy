import SwiftUI

struct ConfigurationToolbarView: View {
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
      presentingPopover.toggle()
    }) {
      Text(store.selectedConfiguration.name)
        .frame(maxWidth: 130)
      Image(systemName: presentingPopover ? "chevron.up" : "chevron.down")
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
        }
      }
      .frame(minWidth: 250, minHeight: 250)
    }
    .sheet(isPresented: $presentingSheet) {
      ConfigurationView(store) { action in
        switch action {
        case .ok(let configuration):
          store.update(configuration)
          presentingSheet = false
        case .cancel:
          presentingSheet = false
        }
      }
      .frame(minWidth: 480)
    }.keyboardShortcut(.init("T"), modifiers: .command)
  }
}

import SwiftUI

struct DetailToolbarConfig {
  var showSearch: Bool = false {
    didSet {
      Swift.print(showSearch)
    }
  }
  var searchQuery: String = ""
}

struct DetailToolbar: ToolbarContent {
  enum Action {
    case addCommand
  }

  @Binding private var config: DetailToolbarConfig
  private let applicationStore: ApplicationStore
  private let searchStore: SearchStore
  private let action: (Action) -> Void

  init(applicationStore: ApplicationStore,
       config: Binding<DetailToolbarConfig>,
       searchStore: SearchStore,
       action: @escaping (Action) -> Void) {
    self.applicationStore = applicationStore
    _config = config
    self.searchStore = searchStore
    self.action = action
  }

  var body: some ToolbarContent {
    ToolbarItemGroup(placement: .primaryAction) {
      Button(
        action: {
          withAnimation(.interactiveSpring()) {
            action(.addCommand)
          }
        },
        label: {
          Label(title: {
            Text("Add command")
          }, icon: {
            Image(systemName: "plus.square.dashed")
              .renderingMode(.template)
              .foregroundColor(Color(.systemGray))
          })
        })

      Spacer()

      SearchField(query: Binding<String>(
        get: { searchStore.query },
        set: { query in
          searchStore.query = query
          config.showSearch = !query.isEmpty
        }))
        .frame(minWidth: 100, idealWidth: 200, maxWidth: .infinity)
//        .popover(
//          isPresented: $config.showSearch,
//          attachmentAnchor: .point(.bottom),
//          arrowEdge: .bottom,
//          content: {
//            
//          })
    }
  }
}

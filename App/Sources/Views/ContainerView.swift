import SwiftUI

struct ContainerView: View {
  enum Focus {
    case sidebar
    case content
    case detail
  }

  enum Action {
    case openScene(AppScene)
    case sidebar(SidebarView.Action)
    case content(ContentView.Action)
    case detail(DetailView.Action)
  }

  @EnvironmentObject var groupStore: GroupStore
  @EnvironmentObject var groupsPublisher: GroupsPublisher
  @ObservedObject var navigationPublisher = NavigationPublisher()

  @Environment(\.openWindow) private var openWindow
  var focus: FocusState<Focus?>.Binding
  let onAction: (Action) -> Void

  private let selectionManager: SelectionManager<ContentViewModel>

  init(focus: FocusState<Focus?>.Binding,
       selectionManager: SelectionManager<ContentViewModel>,
       onAction: @escaping (Action) -> Void) {
    self.focus = focus
    self.selectionManager = selectionManager
    self.onAction = onAction
  }

  var body: some View {
    NavigationSplitView(
      columnVisibility: $navigationPublisher.columnVisibility,
      sidebar: {
        SidebarView { onAction(.sidebar($0)) }
          .focused(focus, equals: .sidebar)
      },
      content: {
        ContentView(selectionManager, onAction: { action in
          onAction(.content(action))
        })
        .focused(focus, equals: .content)
      },
      detail: {
        DetailView(onAction: { onAction(.detail($0)) })
          .focused(focus, equals: .detail)
          .edgesIgnoringSafeArea(.top)
      })
    .navigationSplitViewStyle(.balanced)
    .frame(minWidth: 850, minHeight: 400)
  }
}

struct ContainerView_Previews: PreviewProvider {
  @FocusState static var focus: ContainerView.Focus?

  static var previews: some View {
    ContainerView(focus: $focus, selectionManager: .init()) { _ in }
      .designTime()
      .frame(height: 800)
  }
}

import SwiftUI

struct ContainerView: View {
  enum Action {
    case sidebar(SidebarView.Action)
    case content(ContentView.Action)
  }
  @Namespace var focusNamespace
  @ObserveInjection var inject
  @ObservedObject var navigationPublisher = NavigationPublisher()
  @EnvironmentObject var detailPublisher: DetailPublisher

  private let onAction: (Action) -> Void

  init(onAction: @escaping (Action) -> Void) {
    self.onAction = onAction
  }

  var body: some View {
    NavigationSplitView(
      columnVisibility: $navigationPublisher.columnVisibility,
      sidebar: {
        SidebarView(onAction: { onAction(.sidebar($0)) })
          .frame(minWidth: 200, idealWidth: 310)
      },
      content: {
        ContentView(onAction: { onAction(.content($0)) })
          .navigationSubtitle("Workflows")
          .frame(minWidth: 270)
      },
      detail: {
        DetailView()
      })
    .focusScope(focusNamespace)
    .enableInjection()
  }
}

struct ContainerView_Previews: PreviewProvider {
  static var previews: some View {
    ContainerView { _ in }
      .designTime()
  }
}

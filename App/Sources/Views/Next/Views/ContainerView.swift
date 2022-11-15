import SwiftUI

struct ContainerView: View {
  enum Action {
    case sidebar(SidebarView.Action)
    case content(ContentView.Action)
    case detail(DetailView.Action)
  }
  @ObserveInjection var inject
  @EnvironmentObject var groupsPublisher: GroupsPublisher
  @ObservedObject var navigationPublisher = NavigationPublisher()

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
          .toolbar {
            ToolbarItemGroup(placement: .automatic) {
              Button(action: {
                onAction(.content(.addWorkflow))
              },
                     label: {
                Label(title: {
                  Text("Add workflow")
                }, icon: {
                  Image(systemName: "rectangle.stack.badge.plus")
                    .renderingMode(.template)
                    .foregroundColor(Color(.systemGray))
                })
              })
            }          }
          .navigationTitle(groupsPublisher.selections.first?.name ?? "")
          .navigationSubtitle("Workflows")
          .frame(minWidth: 270)
      },
      detail: {
        DetailView(onAction: { onAction(.detail($0)) })
          .frame(minWidth: 270)
      })
    .frame(minWidth: 880, minHeight: 400)
    .enableInjection()
  }
}

struct ContainerView_Previews: PreviewProvider {
  static var previews: some View {
    ContainerView { _ in }
      .designTime()
  }
}

import SwiftUI

struct ContainerView: View {
  enum Action {
    case openScene(AppScene)
    case sidebar(SidebarView.Action)
    case content(ContentView.Action)
    case detail(DetailView.Action)
  }
  @ObserveInjection var inject
  @EnvironmentObject var groupStore: GroupStore
  @EnvironmentObject var groupsPublisher: GroupsPublisher
  @ObservedObject var navigationPublisher = NavigationPublisher()

  @Environment(\.openWindow) private var openWindow
  private let onAction: (Action) -> Void

  init(onAction: @escaping (Action) -> Void) {
    self.onAction = onAction
  }

  var body: some View {
    NavigationSplitView(
      columnVisibility: $navigationPublisher.columnVisibility,
      sidebar: {
        SidebarView { onAction(.sidebar($0)) }
          .toolbar {
            ToolbarItemGroup {
              Spacer()
              Button(action: { onAction(.openScene(.addGroup)) },
                     label: {
                Label(title: {
                  Text("Add group")
                }, icon: {
                  Image(systemName: "folder.badge.plus")
                    .renderingMode(.template)
                    .foregroundColor(Color(.systemGray))
                })
              })
            }
          }
      },
      content: {
        ContentView(onAction: { onAction(.content($0)) })
          .toolbar {
            ToolbarItemGroup(placement: .navigation) {
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
            }
          }
          .navigationTitle(groupsPublisher.selections.first?.name ?? "")
          .navigationSubtitle("Workflows")
      },
      detail: {
        DetailView(onAction: { onAction(.detail($0)) })
          .navigationTitle(groupsPublisher.selections.first?.name ?? "")
          .navigationSubtitle("Workflows")

      })
    .navigationSplitViewStyle(.balanced)
    .frame(minWidth: 850, minHeight: 400)
    .enableInjection()
  }
}

struct ContainerView_Previews: PreviewProvider {
  static var previews: some View {
    ContainerView { _ in }
      .designTime()
      .frame(height: 800)
  }
}

import SwiftUI

struct GroupList: View {
  enum Action {
    case newGroup
  }

  static let idealWidth: CGFloat = 300

  @ObservedObject var controller: AnyViewController<[Group], Action>
  @State private var selection: Group?
  private var groups: [Group] { controller.state }

  var body: some View {
    NavigationView {
      List {
        ForEach(groups) { group in
          NavigationLink(
            destination: WorkflowList(workflows: group.workflows),
            tag: group,
            selection: $selection
          ) {
            GroupListCell(group: group)
          }
        }
        .onAppear(perform: {
          selection = groups.first
        })
      }
      .listStyle(SidebarListStyle())
      .frame(
        minWidth: 200,
        idealWidth: Self.idealWidth,
        maxWidth: Self.idealWidth,
        maxHeight: .infinity
      )
    }
  }
}

// MARK: - Previews

struct GroupList_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    GroupList(controller: PreviewController().erase())
  }
}

private final class PreviewController: ViewController {
  let state = ModelFactory().groupList()
  func perform(_ action: GroupList.Action) {}
}

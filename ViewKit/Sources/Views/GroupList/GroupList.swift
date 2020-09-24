import SwiftUI

public struct GroupList: View {
  public typealias Controller = AnyViewController<[GroupViewModel], Action>
  public enum Action {
    case newGroup
  }

  static let idealWidth: CGFloat = 300

  @ObservedObject var controller: Controller
  @State private var selection: GroupViewModel?
  @State private var searchText: String = ""
  private var groups: [GroupViewModel] { controller.state }

  public init(controller: Controller) {
    self.controller = controller
  }

  public var body: some View {
    NavigationView {
      VStack(alignment: .leading, spacing: 0) {
        TextField("Search", text: $searchText)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .frame(height: 48)
          .padding(.horizontal, 12)
        Text("Groups")
          .padding(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 0))
          .font(.subheadline)
          .foregroundColor(Color.secondary)
        List(groups, selection: $selection) { group in
          NavigationLink(
            destination: WorkflowList(workflows: group.workflows),
            tag: group,
            selection: $selection
          ) {
            GroupListCell(group: group)
              .padding(.leading, 2)
          }
          .onAppear(perform: {
              selection = selection ?? groups.first
          })
        }
        .listStyle(SidebarListStyle())
        Spacer()
        Button("+ Add Group", action: {
          controller.perform(.newGroup)
        })
        .buttonStyle(PlainButtonStyle())
        .padding(.init(top: 0, leading: 8, bottom: 8, trailing: 0))
      }.frame(
        minWidth: 250,
        maxWidth: 250,
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

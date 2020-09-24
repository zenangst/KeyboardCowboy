import SwiftUI

public struct GroupList: View {
  public typealias Controller = AnyViewController<[GroupViewModel], Action>
  public enum Action {
    case newGroup
  }

  static let idealWidth: CGFloat = 300

  @ObservedObject var controller: Controller
  @State private var selection: GroupViewModel?
  private var groups: [GroupViewModel] { controller.state }

  public init(controller: Controller) {
    self.controller = controller
  }

  public var body: some View {
    NavigationView {
      VStack(alignment: .leading) {
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
              selection = selection ?? groups.first
          })
        }
        .listStyle(SidebarListStyle())
        .frame(
          minWidth: 200,
          maxWidth: Self.idealWidth,
          maxHeight: .infinity
        )
        Spacer()
        Button("+ Add Group", action: {
          controller.perform(.newGroup)
        })
        .buttonStyle(PlainButtonStyle())
        .padding(.init(top: 0, leading: 8, bottom: 8, trailing: 0))
      }
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

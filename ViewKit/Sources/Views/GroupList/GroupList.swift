import SwiftUI

public struct GroupList: View {
  public typealias Controller = AnyViewController<[GroupViewModel], Action>
  public enum Action {
    case newGroup
  }

  static let idealWidth: CGFloat = 300

  @EnvironmentObject var userSelection: UserSelection
  @ObservedObject var controller: Controller

  var groups: [GroupViewModel] { controller.state }

  public init(controller: Controller) {
    self.controller = controller
  }

  public var body: some View {
    List(selection: $userSelection.group) {
        ForEach(groups) { group in
          GroupListCell(group: group)
            .tag(group)
            .onTapGesture(count: 1, perform: {
              userSelection.group = group
            })
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
      .listStyle(SidebarListStyle())
      .onAppear {
        if userSelection.group == nil {
          userSelection.group = groups.first
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
      .frame(width: GroupList.idealWidth, height: 480)
      .environmentObject(UserSelection())
  }
}

private final class PreviewController: ViewController {
  let state = ModelFactory().groupList()
  func perform(_ action: GroupList.Action) {}
}

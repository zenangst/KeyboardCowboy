import SwiftUI

public class UserSelection: ObservableObject {
  @Published var group: GroupViewModel?
  @Published var workflow: WorkflowViewModel?

  public init() {}
}

public struct MainView: View {
  public typealias GroupController = AnyViewController<[GroupViewModel], GroupList.Action>

  @ObservedObject var groupController: GroupController
  @EnvironmentObject var userSelection: UserSelection
  @State private var searchText: String = ""

  public init(groupController: GroupController) {
    self.groupController = groupController
  }

  public var body: some View {
    NavigationView {
      VStack(alignment: .leading) {
        TextField("Search", text: $searchText)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .frame(height: 48)
          .padding(.horizontal, 12)
        GroupList(controller: groupController)
          .frame(minWidth: 200, maxWidth: 250)
      }

      if userSelection.group != nil {
        WorkflowList(group: userSelection.group)
          .frame(minWidth: 250, idealWidth: 250, maxWidth: 250)
      }

      if userSelection.workflow != nil {
        WorkflowView(workflow: userSelection.workflow!)
          .frame(minWidth: 600, maxWidth: .infinity)
      }
    }
  }
}

struct MainView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    MainView(groupController: PreviewController().erase())
      .environmentObject(UserSelection())
      .frame(width: 960, height: 480, alignment: .leading)
  }
}

private final class PreviewController: ViewController {
  let state = ModelFactory().groupList()
  func perform(_ action: GroupList.Action) {}
}

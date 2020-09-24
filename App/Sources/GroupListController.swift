import Foundation
import ViewKit

final class GroupListController: ViewController {
  @Published var state = [GroupViewModel]()

  init(groups: [GroupViewModel]) {
    self.state = groups
  }

  func perform(_ action: GroupList.Action) {
    self.state.append(GroupViewModel(name: "Untitled group", workflows: []))
  }
}

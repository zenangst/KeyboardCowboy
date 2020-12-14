import ModelKit

final class GroupPreviewController: ActionController {
  let state = ModelFactory().groupList()
  func perform(_ action: GroupList.Action) {}
}

import Foundation
import LogicFramework
import ViewKit

class FeatureFactory {
  let logic = ControllerFactory()
  let mapperFactory = ViewModelMapperFactory()

  func groupFeature(_ groups: [Group]) -> GroupsFeatureController {
    GroupsFeatureController(
      groupsController: logic.groupsController(groups: groups),
      mapper: mapperFactory.groupMapper()
    )
  }
}

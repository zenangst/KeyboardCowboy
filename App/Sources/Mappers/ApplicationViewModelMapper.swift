import Foundation
import LogicFramework
import ViewKit
import ModelKit

protocol ApplicationViewModelMapping {
  func map(_ models: [Application]) -> [ApplicationViewModel]
}

class ApplicationViewModelMapper: ApplicationViewModelMapping {
  func map(_ models: [Application]) -> [ApplicationViewModel] {
    models
      .filter({ $0.bundleName.filter({ $0 == "." }).count <= 1 })
      .compactMap(map(model:))
      .sorted(by: { $0.name.lowercased() < $1.name.lowercased() })
  }

  func map(model: Application) -> ApplicationViewModel {
    ApplicationViewModel(id: UUID().uuidString,
                         bundleIdentifier: model.bundleIdentifier,
                         name: model.bundleName,
                         path: model.path)
  }
}

import Foundation
import SwiftUI

final class AppStorageContainer {
  #if DEBUG
  static let store = UserDefaults(suiteName: "com.zenangst.Keyboard-Cowboy.debug")
  #else
  static let store = UserDefaults.standard
  #endif

  static let shared: AppStorageContainer = .init()

  private init() {}

  @AppStorage("selectedConfiguration", store: store) var configId: String = ""
  @AppStorage("selectedGroupIds", store: store) var groupIds = Set<String>()
  @AppStorage("selectedWorkflowIds", store: store) var workflowIds = Set<String>()
  @AppStorage("additionalApplicationPaths", store: store) var additionalApplicationPaths = [String]()
}

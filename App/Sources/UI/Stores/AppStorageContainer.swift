import Foundation
import SwiftUI

@MainActor
final class AppStorageContainer: @unchecked Sendable {
  static let store: UserDefaults = {
    if launchArguments.isEnabled(.runningUnitTests) {
      return UserDefaults(suiteName: "com.zenangst.Keyboard-Cowboy.unit-tests") ?? .standard
    }

    #if DEBUG
    return UserDefaults(suiteName: "com.zenangst.Keyboard-Cowboy.debug") ?? .standard
    #else
    return .standard
    #endif
  }()

  static let shared: AppStorageContainer = .init()

  private init() {}

  @AppStorage("selectedConfiguration", store: store) var configId: String = ""
  @AppStorage("selectedGroupIds", store: store) var groupIds = Set<String>()
  @AppStorage("selectedWorkflowIds", store: store) var workflowIds = Set<String>()
  @AppStorage("additionalApplicationPaths", store: store) var additionalApplicationPaths = [String]()
  @AppStorage("ReleaseNotes", store: store) var releaseNotes: String = ""
}

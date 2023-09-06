import Foundation
import LaunchArguments
import CoreGraphics

let launchArguments = LaunchArgumentsController<LaunchArgument>()
let isRunningPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != nil

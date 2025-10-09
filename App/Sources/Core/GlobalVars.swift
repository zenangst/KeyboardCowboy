import CoreGraphics
import Foundation
import LaunchArguments

let launchArguments = LaunchArgumentsController<LaunchArgument>()
let isRunningPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != nil

import ProjectDescription

let dependencies = Dependencies(
    swiftPackageManager: [
        .remote(url: "https://github.com/zenangst/Apps", requirement: .exact("1.2.0")),
        .remote(url: "https://github.com/zenangst/LaunchArguments", requirement: .exact("1.0.0")),
        .remote(url: "https://github.com/krzysztofzablocki/Inject.git", requirement: .exact("1.1.0")),
        .remote(url: "https://github.com/zenangst/MachPort", requirement: .exact("1.0.2")),
    ],
    platforms: [.macOS]
)

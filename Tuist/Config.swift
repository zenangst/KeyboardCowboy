import ProjectDescription

let config = Config(
    swiftVersion: "5.6.1",
    plugins: [
        .local(path: .relativeToManifest("../../Plugins/Tuist")),
    ]
)

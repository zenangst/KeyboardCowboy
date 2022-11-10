import Foundation

enum DesignTime {

  static var configurationPublisher = ConfigurationPublisher {
    [
      ConfigurationViewModel(),
      ConfigurationViewModel(),
    ]
  }

  static var groupsPublisher = GroupsPublisher {
    [
      GroupViewModel(id: UUID().uuidString, name: "fn-key", image: nil, color: "", symbol: "", count: 24),
      GroupViewModel(id: UUID().uuidString, name: "Finder", image: nil, color: "", symbol: "", count: 10),
      GroupViewModel(id: UUID().uuidString, name: "Safari", image: nil, color: "", symbol: "", count: 5),
      GroupViewModel(id: UUID().uuidString, name: "Xcode", image: nil, color: "", symbol: "", count: 2),
      GroupViewModel(id: UUID().uuidString, name: "Apple News", image: nil, color: "", symbol: "", count: 0),
      GroupViewModel(id: UUID().uuidString, name: "Messages", image: nil, color: "", symbol: "", count: 1),
      GroupViewModel(id: UUID().uuidString, name: "Global", image: nil, color: "", symbol: "", count: 50),
      GroupViewModel(id: UUID().uuidString, name: "Web pages", image: nil, color: "", symbol: "", count: 14),
      GroupViewModel(id: UUID().uuidString, name: "Development", image: nil, color: "", symbol: "", count: 6),
      GroupViewModel(id: UUID().uuidString, name: "Folders", image: nil, color: "", symbol: "", count: 8),
    ]
  }
  static var contentPublisher = ContentPublisher {
   [
    ContentViewModel(id: UUID().uuidString, name: "Open News", images: [], binding: "ƒSpace"),
    ContentViewModel(id: UUID().uuidString, name: "Open Podcast", images: [], binding: "ƒU"),
    ContentViewModel(id: UUID().uuidString, name: "Open Music", images: [], binding: "ƒY"),
    ContentViewModel(id: UUID().uuidString, name: "Open Home", images: [], binding: "ƒH"),
    ContentViewModel(id: UUID().uuidString, name: "Open Twitterific", images: [], binding: "ƒT"),
    ContentViewModel(id: UUID().uuidString, name: "Open System Preferences", images: [], binding: "ƒ."),
    ContentViewModel(id: UUID().uuidString, name: "Open Contacts", images: [], binding: "ƒA"),
    ContentViewModel(id: UUID().uuidString, name: "Open Terminal", images: [], binding: "ƒ§"),
    ContentViewModel(id: UUID().uuidString, name: "Open Discord", images: [], binding: "ƒD"),
    ContentViewModel(id: UUID().uuidString, name: "Open Preview", images: [], binding: "ƒP"),
    ContentViewModel(id: UUID().uuidString, name: "Open Teams", images: [], binding: "ƒG"),
    ContentViewModel(id: UUID().uuidString, name: "Open Slack", images: [], binding: "ƒV"),
    ContentViewModel(id: UUID().uuidString, name: "Open Find My", images: [], binding: "ƒB"),
    ContentViewModel(id: UUID().uuidString, name: "Open Messages", images: [], binding: "ƒD"),
    ContentViewModel(id: UUID().uuidString, name: "Open Mail", images: [], binding: "ƒM"),
    ContentViewModel(id: UUID().uuidString, name: "Open Calendar", images: [], binding: "ƒC"),
    ContentViewModel(id: UUID().uuidString, name: "Open Reminders", images: [], binding: "ƒR"),
    ContentViewModel(id: UUID().uuidString, name: "Open Notes", images: [], binding: "ƒN"),
    ContentViewModel(id: UUID().uuidString, name: "Open Safari", images: [], binding: "ƒS"),
    ContentViewModel(id: UUID().uuidString, name: "Open Finder", images: [], binding: "ƒF"),
    ContentViewModel(id: UUID().uuidString, name: "Open Photos", images: [], binding: "ƒI"),
    ContentViewModel(id: UUID().uuidString, name: "Open Stocks", images: [], binding: "ƒS"),
    ContentViewModel(id: UUID().uuidString, name: "Open Keyboard Cowboy", images: [], binding: "⌥ƒ0"),
    ContentViewModel(id: UUID().uuidString, name: "Open Numbers", images: [], binding: "⌥ƒN"),
    ContentViewModel(id: UUID().uuidString, name: "Open Pages", images: [], binding: "⌥ƒP"),
    ContentViewModel(id: UUID().uuidString, name: "Open Keynote", images: [], binding: "⌥ƒK"),
    ContentViewModel(id: UUID().uuidString, name: "Open Quick Run", images: [], binding: "ƒK"),
   ]
  }
  static var detailPublisher = DetailPublisher {
    .single(detail)
  }

  static var detail: DetailViewModel {
    DetailViewModel(
      id: UUID().uuidString,
      name: "Open News",
      isEnabled: true,
      trigger: .keyboardShortcuts(["fn", "Space"]),
      commands: [
        .init(id: UUID().uuidString,
              name: "Open News",
              image: nil,
              isEnabled: true)
      ])
  }
}

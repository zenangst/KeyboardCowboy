import Foundation

enum Raycast {
  @MainActor
  final class Store: ObservableObject {
    @Published var containers = [Container]()
    let paths: [URL]
    var watchers = [FileWatcher]()

    init() {
      let userDirectory = FileManager.default.homeDirectoryForCurrentUser
        .appending(path: ".config/raycast/extensions")
      self.paths = [userDirectory]
      do {
        var isDirectory: ObjCBool = true
        self.watchers = try paths.compactMap {
          guard FileManager.default.fileExists(atPath: $0.path(), isDirectory: &isDirectory) else {
            return nil
          }
          try index($0)
          return try FileWatcher($0, handler: { [weak self] url in
            try? self?.index(url)
          })
        }
      } catch {
        print(error)
      }
    }

    private func index(_ url: URL) throws {
      let jsonDecoder = JSONDecoder()
      let folders = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
      var extensions: [Extension] = []
      for folder in folders where !folder.absoluteString.contains("node_modules") {
        let data = try Data(contentsOf: folder.appendingPathComponent("package.json"))
        let raycastExtension = try jsonDecoder.decode(Extension.self, from: data)
        extensions.append(raycastExtension)
      }

      extensions.sort(by: { $0.title < $1.title })

      let container = Container(id: url.absoluteString, url: url, extensions: extensions)
      var newContainers = containers
      newContainers.removeAll(where: { $0.id == container.id })
      newContainers.append(container)
      newContainers.sort { $0.id < $1.id }
      containers = newContainers
    }
  }

  struct Container: Identifiable {
    let id: String
    let url: URL
    let extensions: [Extension]
  }

  struct Extension: Identifiable, Decodable {
    let id: String
    let author: String
    let name: String
    let title: String
    let commands: [Command]

    enum CodingKeys: CodingKey {
      case id
      case author
      case name
      case title
      case commands
    }

    init(from decoder: any Decoder) throws {
      let container: KeyedDecodingContainer<Raycast.Extension.CodingKeys> = try decoder.container(keyedBy: Raycast.Extension.CodingKeys.self)
      let author = try container.decode(String.self, forKey: Raycast.Extension.CodingKeys.author)
      let name = try container.decode(String.self, forKey: Raycast.Extension.CodingKeys.name)
      let title = try container.decode(String.self, forKey: Raycast.Extension.CodingKeys.title)
      let id = author + name
      let commands = try container.decode([Command].self, forKey: Raycast.Extension.CodingKeys.commands)
        .map { Raycast.Extension.Command($0, path: "raycast://extensions/\(author)/\(name)/\($0.name)") }

      self.author = author
      self.name = name
      self.title = title
      self.commands = commands
      self.id = id
    }

    struct Command: Identifiable, Decodable {
      let id: String
      let name: String
      let title: String
      fileprivate(set) var path: String

      enum CodingKeys: CodingKey {
        case id
        case name
        case title
      }

      init(_ command: Command, path: String) {
        self.id = command.id
        self.name = command.name
        self.title = command.title
        self.path = path
      }

      init(from decoder: any Decoder) throws {
        let container: KeyedDecodingContainer<Raycast.Extension.Command.CodingKeys> = try decoder.container(keyedBy: Raycast.Extension.Command.CodingKeys.self)
        self.name = try container.decode(String.self, forKey: Raycast.Extension.Command.CodingKeys.name)
        self.title = try container.decode(String.self, forKey: Raycast.Extension.Command.CodingKeys.title)
        self.id = name + title
        self.path = ""
      }
    }
  }
}

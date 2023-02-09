import Foundation
import UniformTypeIdentifiers

final class GenericDroplet<Element>: NSObject, Codable, NSItemProviderReading, NSItemProviderWriting where Element: Codable {
  static var readableTypeIdentifiersForItemProvider: [String] { [UTType.data.identifier] }
  static var writableTypeIdentifiersForItemProvider: [String] { [UTType.data.identifier] }

  let models: [Element]

  init(_ models: [Element]) {
    self.models = models
    super.init()
  }

  func loadData(withTypeIdentifier typeIdentifier: String,
                forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
    let progress = Progress(totalUnitCount: 100)
    do {
      let encoder = JSONEncoder()
      encoder.outputFormatting = .prettyPrinted
      let data = try encoder.encode(self)
      progress.completedUnitCount = 100
      completionHandler(data, nil)
    } catch {
      completionHandler(nil, error)
    }

    return progress
  }

  static func object(withItemProviderData data: Data, typeIdentifier: String) throws -> Self {
    let decoder = JSONDecoder()
    do {
      return try decoder.decode(self, from: data)
    } catch {
      fatalError("Err")
    }
  }
}

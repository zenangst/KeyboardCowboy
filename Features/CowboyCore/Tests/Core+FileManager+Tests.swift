import CowboyCore
import Foundation
import Testing

@Test func contentsAtPath() throws {
  let fileManager = Core.FileManager(.testing)

  #expect(fileManager.contents(atPath: "foo") == nil)

  let input = Data("foo".utf8)

  Core.FileManager.Testing.$mock.withValue(.init(contentsAtPath: input)) {
    let output = fileManager.contents(atPath: "foo")
    let string = String(data: output!, encoding: .utf8)
    #expect(string == "foo")
  }
}

@Test func createTemporaryDirectory() throws {
  enum LocalError: Error {
    case customError
  }

  let fileManager = Core.FileManager(.testing)
  let foo = try fileManager.createTemporaryDirectory()

  #expect(!foo.absoluteString.isEmpty)

  Core.FileManager.Testing.$mock.withValue(.init(createDirectoryAtUrl: { throw LocalError.customError })) {
    #expect(throws: LocalError.self) {
      try fileManager.createTemporaryDirectory()
    }
  }
}

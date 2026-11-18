import FileSystem
import Foundation
import Testing

@Test func contentsAtPath() throws {
  let fileManager = FileSystem.FileManager(.testing)

  #expect(fileManager.contents(atPath: "foo") == nil)

  let input = Data("foo".utf8)

  FileSystem.FileManager.Testing.$mock.withValue(.init(contentsAtPath: input)) {
    let output = fileManager.contents(atPath: "foo")
    let string = String(data: output!, encoding: .utf8)
    #expect(string == "foo")
  }
}

@Test func createTemporaryDirectory() throws {
  enum LocalError: Error {
    case customError
  }

  let fileManager = FileSystem.FileManager(.testing)
  let foo = try fileManager.createTemporaryDirectory()

  #expect(!foo.absoluteString.isEmpty)

  FileSystem.FileManager.Testing.$mock.withValue(.init(createDirectoryAtUrl: { throw LocalError.customError })) {
    #expect(throws: LocalError.self) {
      try fileManager.createTemporaryDirectory()
    }
  }
}

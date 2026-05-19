import System

extension JXA {
  enum Error: Swift.Error {
    case unableToFindFile(FilePath)
  }
}

import LogicFramework

class WindowListProviderMock: WindowListProviding {
  var owners: [String]

  init(_ owners: [String]) {
    self.owners = owners
  }

  func windowOwners() -> [String] {
    owners
  }
}

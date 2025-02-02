extension WindowSpace {
  actor MapContainer {
    typealias OwnerPid = Int
    typealias BundleIdentifier = String
    var storage: [OwnerPid: BundleIdentifier] = [:]

    func lookup(_ pid: OwnerPid) -> BundleIdentifier? {
      storage[pid]
    }
  }
}

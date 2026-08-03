import Cocoa
import System
import Testing

@Test func filePathExpandsTilde() {
  let path = FilePath("~/Documents")

  #expect(
    path.path == ("~/Documents" as NSString).expandingTildeInPath,
  )
}

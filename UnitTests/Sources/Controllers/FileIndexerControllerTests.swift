@testable import LogicFramework
@testable import Keyboard_Cowboy
import Combine
import XCTest

class FileIndexerControllerTests: XCTestCase {
  private let match: (URL) -> Bool = { $0.absoluteString.contains(".app") }
  private let handler: (URL) -> Match? = { url -> Match? in
    url.absoluteString.contains("Finder")
      ? Match(url: url)
      : nil
  }

//  func testSynchronousFileIndexing() {
//    let expectedResult = [Match(url: URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app/"))]
//    let controller = FileIndexController(urls: [URL.init(fileURLWithPath: "/System/Library/CoreServices")])
//
//    measure {
//      let result = controller.index(match: match, handler: handler)
//      XCTAssertEqual(expectedResult, result)
//    }
//  }

//  func testPerformance() {
//    var start = CACurrentMediaTime()
//    let controller1 = FileIndexController(urls: [URL.init(fileURLWithPath: "/")])
//    _ = controller1.index(match: match, handler: handler)
//    let entireDiskResult = CACurrentMediaTime() - start
//
//    start = CACurrentMediaTime()
//
//    let controller2 = FileIndexController(urls: ApplicationController.commonPaths())
//    _ = controller2.index(match: match, handler: handler)
//    let targetedDirectoriesResult = CACurrentMediaTime() - start
//
//    XCTAssertLessThan(entireDiskResult, targetedDirectoriesResult)
//  }

//  func testAsynchronousFileIndexing() {
//    var cancellables = [AnyCancellable]()
//    let expectedResult = [Match(url: URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app/"))]
//    let completionExpectation = self.expectation(description: "Expect completion")
//    let resultExpectation = self.expectation(description: "Expect results")
//    let controller = FileIndexController(urls: [URL.init(fileURLWithPath: "/System/Library/CoreServices")])
//
//    controller.asyncIndex(match: match, handler: handler)
//      .sink(receiveCompletion: { _ in
//        completionExpectation.fulfill()
//      }, receiveValue: { result in
//        XCTAssertEqual(expectedResult, result)
//        resultExpectation.fulfill()
//      }).store(in: &cancellables)
//
//    wait(for: [resultExpectation, completionExpectation], timeout: 10.0, enforceOrder: true)
//  }
}

private struct Match: Equatable {
  var url: URL
}

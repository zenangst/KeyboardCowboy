import Foundation
import XCTest
@testable import ViewKit
@testable import LogicFramework
@testable import Keyboard_Cowboy

class ApplicationViewModelMapperTests: XCTestCase {
  let mapperFactory = ViewModelMapperFactory()
  let modelFactory = LogicFramework.ModelFactory()

  func testMappingApplicationViewModel() {
    let mapper = mapperFactory.applicationMapper()
    let subject = Application.finder()
    let result = mapper.map([subject])

    XCTAssertEqual(result, [ApplicationViewModel.finder(id: result[0].id)])
  }

}

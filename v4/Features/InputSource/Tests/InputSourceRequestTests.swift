import Foundation
import InputSourceFeature
import XCTest

final class InputSourceRequestTests: XCTestCase {
  func testMissingNameFallsBackToExactSourceID() throws {
    let data = Data(#"{"id":"request","inputSourceId":"com.example.layout-1:en_US"}"#.utf8)
    let request = try JSONDecoder().decode(InputSourceRequest.self, from: data)
    XCTAssertEqual(request.id, "request")
    XCTAssertEqual(request.name, "com.example.layout-1:en_US")
    XCTAssertEqual(request.inputSourceId, "com.example.layout-1:en_US")
  }

  func testExplicitNameRoundTrips() throws {
    let data = Data(#"{"id":"request","inputSourceId":"source","name":"Display Name"}"#.utf8)
    let request = try JSONDecoder().decode(InputSourceRequest.self, from: data)
    XCTAssertEqual(request.name, "Display Name")
    XCTAssertEqual(try JSONDecoder().decode(InputSourceRequest.self, from: JSONEncoder().encode(request)), request)
  }

  func testRequiredIDsMustBePresent() {
    for json in [#"{"inputSourceId":"source"}"#, #"{"id":"request"}"#] {
      XCTAssertThrowsError(try JSONDecoder().decode(InputSourceRequest.self, from: Data(json.utf8)))
    }
  }
}

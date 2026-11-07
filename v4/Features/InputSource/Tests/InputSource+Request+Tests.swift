import Foundation
import InputSourceFeature
import InputSourceSystem
import XCTest

// Mirrors the host's synthesized keyboard-kind representation without changing it.
private enum KeyboardKindFixture: Codable, Equatable {
  case inputSource(command: InputSource.Request)
}

final class InputSourceRequestTests: XCTestCase {
  func testMissingNameFallsBackToExactSourceID() throws {
    let data = Data(#"{"id":"request","inputSourceId":"com.example.layout-1:en_US"}"#.utf8)
    let request = try JSONDecoder().decode(InputSource.Request.self, from: data)
    XCTAssertEqual(request.id, "request")
    XCTAssertEqual(request.name, "com.example.layout-1:en_US")
    XCTAssertEqual(request.inputSourceId, "com.example.layout-1:en_US")
  }

  func testExplicitNameRoundTrips() throws {
    let data = Data(#"{"id":"request","inputSourceId":"source","name":"Display Name"}"#.utf8)
    let request = try JSONDecoder().decode(InputSource.Request.self, from: data)
    XCTAssertEqual(request.name, "Display Name")
    XCTAssertEqual(try JSONDecoder().decode(InputSource.Request.self, from: JSONEncoder().encode(request)), request)
  }

  func testRequiredIDsMustBePresent() {
    for json in [#"{"inputSourceId":"source"}"#, #"{"id":"request"}"#] {
      XCTAssertThrowsError(try JSONDecoder().decode(InputSource.Request.self, from: Data(json.utf8)))
    }
  }

  func testKeyboardKindPreservesNestedDiscriminator() throws {
    let data = Data(#"{"inputSource":{"command":{"id":"nested-id","inputSourceId":"com.example.layout:en-US"}}}"#.utf8)
    let kind = try JSONDecoder().decode(KeyboardKindFixture.self, from: data)
    XCTAssertEqual(kind, .inputSource(command: InputSource.Request(
      id: "nested-id", inputSourceId: "com.example.layout:en-US", name: "com.example.layout:en-US"
    )))
    let encoded = try JSONEncoder().encode(kind)
    XCTAssertEqual(try JSONDecoder().decode(KeyboardKindFixture.self, from: encoded), kind)
    let object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
    let payload = try XCTUnwrap(object["inputSource"] as? [String: Any])
    XCTAssertNotNil(payload["command"])
  }
}

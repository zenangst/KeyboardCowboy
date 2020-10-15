import Foundation
import XCTest
import LogicFramework

class IdentifiableCollectionTests: XCTestCase {

  func testAddingElement() throws {
    var subject = [Item]()
    let item = Item(id: "A", contents: "A")
    let expected = [item]

    subject.add(item)

    XCTAssertEqual(expected, subject)
  }

  func testReplacingElement() throws {
    var subject = [
      Item(id: "A", contents: "A"),
      Item(id: "B", contents: "B"),
      Item(id: "C", contents: "C")
    ]

    let item = Item(id: "B", contents: "D")

    let expected = [
      Item(id: "A", contents: "A"),
      item,
      Item(id: "C", contents: "C")
    ]

    try subject.replace(item)

    XCTAssertEqual(expected, subject)
  }

  func testRemovingElement() throws {
    var subject = [
      Item(id: "A", contents: "A"),
      Item(id: "B", contents: "B"),
      Item(id: "C", contents: "C")
    ]

    let item = Item(id: "B", contents: "B")

    let expected = [
      Item(id: "A", contents: "A"),
      Item(id: "C", contents: "C")
    ]

    try subject.remove(item)

    XCTAssertEqual(expected, subject)
  }

  func testMovingElement() throws {
    var subject = [
      Item(id: "A", contents: "A"),
      Item(id: "B", contents: "B"),
      Item(id: "C", contents: "C")
    ]

    let item = Item(id: "C", contents: "C")
    let firstResult = [
      Item(id: "C", contents: "C"),
      Item(id: "A", contents: "A"),
      Item(id: "B", contents: "B")
    ]

    try subject.move(item, to: 0)
    XCTAssertEqual(firstResult, subject)

    let secondResult = [
      Item(id: "A", contents: "A"),
      Item(id: "B", contents: "B"),
      Item(id: "C", contents: "C")
    ]

    try subject.move(item, to: 2)
    XCTAssertEqual(secondResult, subject)
  }
}

struct Item: Identifiable, Equatable {
  let id: String
  let contents: String
}

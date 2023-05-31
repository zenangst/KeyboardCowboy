@testable import Keyboard_Cowboy
import Apps
import XCTest

class DropCommandsControllerTests: XCTestCase {
  static let rootPath = URL(fileURLWithPath: #file)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()

  func testGeneratingApplicationCommand() {
    let commands = DropCommandsController.generateCommands(from: [
      URL(fileURLWithPath: "/System/Applications/Notes.app")
    ], applications: [
      Application(bundleIdentifier: "com.apple.Notes",
                  bundleName: "Notes",
                  path: "/System/Applications/Notes.app")
    ])

    guard case .application(let applicationCommand) = commands.first else {
      XCTFail("Expected application command")
      return
    }

    XCTAssertEqual(applicationCommand.name, "Open Notes")
  }

  func testGeneratingAppleScriptCommand() {
    let path = Self.rootPath
      .appendingPathComponent("Fixtures")
      .appendingPathComponent("applescripts")
      .appendingPathComponent("AppleScript.scpt")

    let commands = DropCommandsController.generateCommands(from: [
      URL(fileURLWithPath: path.absoluteString)
    ], applications: [])
    guard case .script(let scriptCommand) = commands.first else {
      XCTFail("Expected script command")
      return
    }

    XCTAssertEqual(scriptCommand.name, "Run AppleScript.scpt")
  }

  func testGeneratingShellScriptCommand() {
    let path = Self.rootPath
      .appendingPathComponent("Fixtures")
      .appendingPathComponent("shellscripts")
      .appendingPathComponent("script.sh")

    let commands = DropCommandsController.generateCommands(from: [
      URL(fileURLWithPath: path.absoluteString)
    ], applications: [])

    guard case .script(let scriptCommand) = commands.first else {
      XCTFail("Expected script command")
      return
    }

    XCTAssertEqual(scriptCommand.name, "Run script.sh")
  }

  func testGeneratingFileCommand() {
    let path = Self.rootPath
      .appendingPathComponent("Fixtures")
      .appendingPathComponent("files")
      .appendingPathComponent("file")

    let commands = DropCommandsController.generateCommands(from: [
      URL(fileURLWithPath: path.absoluteString)
    ], applications: [])

    guard case .open(let openCommand) = commands.first else {
      XCTFail("Expected open command")
      return
    }

    XCTAssertEqual(openCommand.name, "Open file")
  }

  func testGeneratingWebCommand() {
    let commands = DropCommandsController.generateCommands(from: [URL(string: "https://www.apple.com")!],
                                                           applications: [])

    guard case .open(let openCommand) = commands.first else {
      XCTFail("Expected open command")
      return
    }

    XCTAssertEqual(openCommand.name, "Open www.apple.com")
  }
}

import Foundation
import ProcessSystem
@testable import ShortcutsFeature
import Testing

private let first = "00000000-0000-4000-8000-000000000001"
private let second = "00000000-0000-4000-8000-000000000002"
private let third = "00000000-0000-4000-8000-000000000003"

@Test func catalogListsByIdentifierWithoutShell() async throws {
  let catalog = Shortcuts.Catalog.testing()
  #expect(await catalog.entries == nil)
  let listing = "Zoo (\(second))\n日本語 (work)  (\(third))\nZoo (\(first))\nZoo (\(first))\n"
  let mock = ProcessSystem.Process.Mock(observeLaunch: {
    #expect($0.executableURL?.path == "/usr/bin/shortcuts")
    #expect($0.arguments == ["list", "--show-identifiers"])
    #expect($0.environment == nil)
  }, readStandardOutput: { Data(listing.utf8) })
  let entries = try await ProcessSystem.Process.Testing.$mock.withValue(mock) {
    try await catalog.refresh()
  }
  #expect(entries.filter { $0.name == "Zoo" }.map(\.id.uuidString) == [first, second])
  #expect(entries.first(where: { $0.id.uuidString == third })?.name == "日本語 (work) ")
  #expect(entries.count == 3)
  #expect(await catalog.entries == entries)
}

@Test func catalogKeepsLastSuccessfulListingUntilAnEmptyRefresh() async throws {
  let catalog = Shortcuts.Catalog.testing()
  let initial = try await ProcessSystem.Process.Testing.$mock.withValue(
    .init(readStandardOutput: { Data("Entry (\(first))".utf8) }),
  ) { try await catalog.refresh() }
  #expect(initial.count == 1)

  await ProcessSystem.Process.Testing.$mock.withValue(
    .init(terminationStatus: 1, readStandardError: { Data("unavailable".utf8) }),
  ) {
    await #expect(throws: Shortcuts.CatalogError.listingFailed("unavailable")) {
      try await catalog.refresh()
    }
  }
  #expect(await catalog.entries == initial)

  for invalid in [Data("unexpected format\n".utf8), Data([0xFF])] {
    await ProcessSystem.Process.Testing.$mock.withValue(.init(readStandardOutput: { invalid })) {
      await #expect(throws: Shortcuts.CatalogError.invalidListing) { try await catalog.refresh() }
    }
    #expect(await catalog.entries == initial)
  }

  let empty = try await ProcessSystem.Process.Testing.$mock.withValue(
    .init(readStandardOutput: { nil }),
  ) { try await catalog.refresh() }
  #expect(empty.isEmpty)
  #expect(await catalog.entries == [])
}

import Foundation
import RuntimeEnvironment

public extension Shortcuts {
  struct Entry: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let name: String
  }

  enum CatalogError: Error, Equatable {
    case listingFailed(String)
    case invalidListing
  }

  actor Catalog {
    private let environment: RuntimeEnvironment.Mode
    private var pending: Task<[Entry], Error>?

    /// `nil` until the first successful refresh; an empty array means an empty library.
    public private(set) var entries: [Entry]?

    public init() { environment = .production }

    #if DEBUG
    private init(environment: RuntimeEnvironment.Mode) { self.environment = environment }
    static func testing() -> Self { Self(environment: .testing) }
    #endif

    /// Concurrent refreshes share one CLI invocation. Failures leave `entries` unchanged.
    @discardableResult
    public func refresh() async throws -> [Entry] {
      if let pending { return try await pending.value }
      let task = Task { try await reload() }
      pending = task
      return try await task.value
    }

    private func reload() async throws -> [Entry] {
      defer { pending = nil }
      let output = try await launchShortcuts(["list", "--show-identifiers"], environment: environment)
      guard output.status == 0 else {
        throw CatalogError.listingFailed(output.stderr.flatMap { String(data: $0, encoding: .utf8) } ?? "")
      }
      guard let listing = String(data: output.stdout ?? Data(), encoding: .utf8) else {
        throw CatalogError.invalidListing
      }

      // The CLI emits one `name (UUID)` per LF-terminated line. Parse the suffix
      // so spaces and parenthesized text in the name are preserved.
      var seen: Set<UUID> = []
      let parsed = try listing.split(separator: "\n").compactMap { line -> Entry? in
        guard line.hasSuffix(")"), let separator = line.range(of: " (", options: .backwards),
              let id = UUID(uuidString: String(line[separator.upperBound...].dropLast())) else {
          throw CatalogError.invalidListing
        }
        guard seen.insert(id).inserted else { return nil }
        return Entry(id: id, name: String(line[..<separator.lowerBound]))
      }
      let sorted = parsed.sorted {
        let order = $0.name.localizedStandardCompare($1.name)
        return order == .orderedSame ? $0.id.uuidString < $1.id.uuidString : order == .orderedAscending
      }
      entries = sorted
      return sorted
    }
  }
}

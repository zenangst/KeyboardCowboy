import Foundation

public enum Shortcuts {
  public enum CancellationPolicy: Sendable {
    case checkBeforeLaunch
    case ignore
  }

  public enum ExecutionError: Error, Equatable {
    case executionFailed(String)
  }

  public struct Executor: Sendable {
    private let execute: @Sendable (String) async throws -> String?

    public init() {
      self.execute = { identifier in
        try await Task.detached {
          try runProcess(identifier: identifier)
        }.value
      }
    }

    #if DEBUG
    init(execute: @escaping @Sendable (String) async throws -> String?) {
      self.execute = execute
    }
    #endif

    public func run(_ identifier: String, cancellation: CancellationPolicy) async throws -> String? {
      if cancellation == .checkBeforeLaunch { try Task.checkCancellation() }
      return try await execute(identifier)
    }
  }
}

private func runProcess(identifier: String) throws -> String? {
  let process = Process()
  process.executableURL = URL(filePath: "/usr/bin/shortcuts")
  process.arguments = ["run", identifier]
  let stdout = Pipe()
  let stderr = Pipe()
  process.standardOutput = stdout
  process.standardError = stderr
  try process.run()

  let reads = StreamReads(process: process)
  let group = DispatchGroup()
  for (index, handle) in [stdout.fileHandleForReading, stderr.fileHandleForReading].enumerated() {
    group.enter()
    DispatchQueue.global().async {
      reads.read(handle, at: index)
      group.leave()
    }
  }
  group.wait()
  process.waitUntilExit()
  let output = try reads.results()
  if process.terminationStatus != 0 {
    throw Shortcuts.ExecutionError.executionFailed(output[1].flatMap { String(data: $0, encoding: .utf8) } ?? "")
  }
  return output[0].flatMap { String(data: $0, encoding: .utf8) }
}

private final class StreamReads: @unchecked Sendable {
  private let lock = NSLock()
  private let process: Process
  private var data: [Data?] = [nil, nil]
  private var error: (any Error)?

  init(process: Process) { self.process = process }

  func read(_ handle: FileHandle, at index: Int) {
    do {
      let value = try handle.readToEnd()
      lock.lock()
      data[index] = value
      lock.unlock()
    } catch {
      lock.lock()
      if self.error == nil {
        self.error = error
        if process.isRunning { process.terminate() }
      }
      lock.unlock()
    }
  }

  func results() throws -> [Data?] {
    lock.lock()
    defer { lock.unlock() }
    if let error { throw error }
    return data
  }
}

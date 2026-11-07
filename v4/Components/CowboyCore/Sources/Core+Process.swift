import Foundation
import Darwin

public extension Core {
  final class Process {
    public enum CaptureError: Swift.Error, Equatable {
      case standardOutputLimitExceeded(limit: Int)
      case standardErrorLimitExceeded(limit: Int)
    }

    public static let standardOutputCaptureLimit = 64 * 1024 * 1024
    public static let standardErrorCaptureLimit = 64 * 1024 * 1024

    public enum LaunchStyle: Equatable {
      case shell(String)
      case headless(String)

      public var source: String {
        switch self {
        case .shell(let string): string
        case .headless(let string): string
        }
      }
    }

    enum Mode {
      case production(Foundation.Process)
      #if DEBUG
      case testing(Storage)
      #endif
    }

    let mode: Mode
    public let launchStyle: LaunchStyle

    public var arguments: [String]? {
      get {
        switch mode {
        case .production(let process): process.arguments
        #if DEBUG
        case .testing(let storage): storage.arguments
        #endif
        }
      }
      set {
        switch mode {
        case .production(let process): process.arguments = newValue
        #if DEBUG
        case .testing(let storage): storage.arguments = newValue
        #endif
        }
      }
    }

    public var currentDirectoryURL: URL? {
      get {
        switch mode {
        case .production(let process): process.currentDirectoryURL
        #if DEBUG
        case .testing(let storage): storage.currentDirectoryURL
        #endif
        }
      }
      set {
        switch mode {
        case .production(let process): process.currentDirectoryURL = newValue
        #if DEBUG
        case .testing(let storage): storage.currentDirectoryURL = newValue
        #endif
        }
      }
    }

    public var executableURL: URL? {
      get {
        switch mode {
        case .production(let process): process.executableURL
        #if DEBUG
        case .testing(let storage): storage.executableURL
        #endif
        }
      }
      set {
        switch mode {
        case .production(let process): process.executableURL = newValue
        #if DEBUG
        case .testing(let storage): storage.executableURL = newValue
        #endif
        }
      }
    }

    public var environment: [String: String]? {
      get {
        switch mode {
        case .production(let process): process.environment
        #if DEBUG
        case .testing(let storage): storage.environment
        #endif
        }
      }
      set {
        switch mode {
        case .production(let process): process.environment = newValue
        #if DEBUG
        case .testing(let storage): storage.environment = newValue
        #endif
        }
      }
    }

    public var standardError: Core.Pipe? {
      didSet {
        guard case .production(let process) = mode else {
          return
        }

        switch standardError?.mode {
        case .production(let pipe):
          process.standardError = pipe
        default:
          process.standardError = standardError
        }
      }
    }

    public var standardOutput: Core.Pipe? {
      didSet {
        guard case .production(let process) = mode else { return }

        switch standardOutput?.mode {
        case .production(let pipe):
          process.standardOutput = pipe
        default:
          process.standardOutput = standardOutput
        }
      }
    }

    public let source: String

    /// Available after the process has exited.
    public var terminationStatus: Int32 {
      switch mode {
      case .production(let process): process.terminationStatus
      #if DEBUG
      case .testing: Testing.mock.terminationStatus
      #endif
      }
    }

    public var terminationReason: Foundation.Process.TerminationReason {
      switch mode {
      case .production(let process): process.terminationReason
      #if DEBUG
      case .testing: Testing.mock.terminationReason
      #endif
      }
    }

    public init(_ env: Environment, launchStyle: LaunchStyle) {
      self.source = launchStyle.source
      self.launchStyle = launchStyle

      self.mode = switch env {
      case .production: .production(Foundation.Process())
      #if DEBUG
      case .testing: .testing(Storage())
      #endif
      }
    }

    public func run() throws {
      switch mode {
      case .production(let process):
        try process.run()
      #if DEBUG
      case .testing(let storage):
        Testing.mock.observeLaunch?(LaunchConfiguration(
          arguments: storage.arguments,
          currentDirectoryURL: storage.currentDirectoryURL,
          environment: storage.environment,
          executableURL: storage.executableURL
        ))
        try Testing.mock.run?()
      #endif
      }
    }

    public func waitUntilExit() {
      switch mode {
      case .production(let process):
        process.waitUntilExit()
      #if DEBUG
      case .testing:
        Testing.mock.waitUntilExit?()
      #endif
      }
    }

    /// Captures both streams concurrently in memory, without limits or cancellation
    /// checks. Waits for EOF (including inherited pipe handles) and reaps the child.
    public func runAndCaptureOutputUnbounded() throws -> (stdout: Data?, stderr: Data?) {
      #if DEBUG
      if case .testing = mode {
        try run()
        defer { waitUntilExit() }
        let stdout = try Testing.mock.readStandardOutput.map { try $0() } ?? standardOutput?.fileHandleForReading.readToEnd()
        let stderr = try Testing.mock.readStandardError.map { try $0() } ?? standardError?.fileHandleForReading.readToEnd()
        return (stdout, stderr)
      }
      #endif
      guard case .production(let child) = mode,
            case .production(let stdout) = standardOutput?.mode,
            case .production(let stderr) = standardError?.mode else {
        throw CocoaError(.fileReadUnknown)
      }
      try run()
      defer {
        standardOutput?.closeReading()
        standardError?.closeReading()
      }
      let reads = UnboundedStreamReads(process: child)
      let group = DispatchGroup()
      for (index, handle) in [stdout.fileHandleForReading, stderr.fileHandleForReading].enumerated() {
        group.enter()
        DispatchQueue.global().async {
          reads.read(handle, at: index)
          group.leave()
        }
      }
      group.wait()
      child.waitUntilExit()
      let result = try reads.results()
      return (result[0], result[1])
    }

    /// Drains both output pipes while the direct child runs. Descendants that keep
    /// the pipes open are allowed a short grace period after the child exits.
    /// Captures at most 64 MiB per stream, throwing the corresponding
    /// `CaptureError` rather than truncating when either limit is exceeded.
    /// Stderr overflow is reported even when stdout would otherwise be preferred.
    /// On capture failure, the direct child is terminated and reaped.
    public func runAndCaptureOutput() throws -> (stdout: Data?, stderr: Data?) {
      try Task.checkCancellation()
      do {
        return try captureOutput()
      } catch {
        try Task.checkCancellation()
        throw error
      }
    }

    private func captureOutput() throws -> (stdout: Data?, stderr: Data?) {
      #if DEBUG
      if case .testing = mode {
        try Task.checkCancellation()
        try run()
        let stdout: Data?
        if let read = Testing.mock.readStandardOutput {
          stdout = try read()
        } else {
          stdout = try standardOutput?.fileHandleForReading.readToEnd()
        }
        let stderr: Data?
        if let read = Testing.mock.readStandardError {
          stderr = try read()
        } else {
          stderr = try standardError?.fileHandleForReading.readToEnd()
        }
        waitUntilExit()
        try Task.checkCancellation()
        return (stdout, stderr)
      }
      #endif
      guard case .production(let child) = mode,
            let output = standardOutput?.readingDescriptor,
            let error = standardError?.readingDescriptor else {
        throw CocoaError(.fileReadUnknown)
      }

      // Atomic O_CLOEXEC avoids the mkstemp/fcntl race with concurrent launches.
      // O_EXCL rejects existing files and symlinks; the file is private and
      // unlinked immediately after creation.
      var spool: Int32 = -1
      var spoolPath = ""
      for _ in 0..<16 {
        spoolPath = (NSTemporaryDirectory() as NSString).appendingPathComponent("cowboy-stderr-\(UUID().uuidString)")
        spool = open(spoolPath, O_RDWR | O_CREAT | O_EXCL | O_CLOEXEC, mode_t(0o600))
        if spool >= 0 { break }
        if errno != EEXIST { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
      }
      guard spool >= 0 else { throw POSIXError(.EEXIST) }
      guard unlink(spoolPath) == 0 else {
        let code = errno
        close(spool)
        throw POSIXError(POSIXErrorCode(rawValue: code) ?? .EIO)
      }
      defer { close(spool) }

      for fd in [output, error] {
        let flags = fcntl(fd, F_GETFL)
        guard flags >= 0, fcntl(fd, F_SETFL, flags | O_NONBLOCK) >= 0 else {
          throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
      }

      try Task.checkCancellation()
      try child.run()
      defer {
        standardOutput?.closeReading()
        standardError?.closeReading()
      }
      var finished = false
      defer {
        if !finished {
          if child.isRunning { kill(child.processIdentifier, SIGKILL) }
          child.waitUntilExit()
        }
      }
      var stdout = Data()
      var stderrSize = 0
      var open = [true, true]
      let descriptors = [output, error]
      var exitedAt: UInt64?
      var pendingAtExit = [Int32](repeating: 0, count: 2)
      var buffer = [UInt8](repeating: 0, count: 65536)
      while open.contains(true) || child.isRunning {
        try Task.checkCancellation()
        let now = DispatchTime.now().uptimeNanoseconds
        if !child.isRunning && exitedAt == nil {
          exitedAt = now
          // Preserve bytes already buffered when the direct child exits, even
          // if a slow spool write consumes the descendant grace period.
          for index in 0..<2 where open[index] {
            // Darwin's FIONREAD (_IOR('f', 127, int)) is not imported by Swift.
            guard ioctl(descriptors[index], 0x4004667f, &pendingAtExit[index]) == 0 else {
              throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
            }
          }
        }
        if let exitedAt, now - exitedAt >= 500_000_000, pendingAtExit.allSatisfy({ $0 <= 0 }) { break }
        var pollDescriptors = descriptors.enumerated().map {
          pollfd(fd: open[$0.offset] ? $0.element : -1, events: Int16(POLLIN), revents: 0)
        }
        let result = poll(&pollDescriptors, nfds_t(pollDescriptors.count), 25)
        if result < 0 {
          if errno == EINTR { continue }
          throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
        for index in 0..<2 where open[index] && pollDescriptors[index].revents != 0 {
          if pollDescriptors[index].revents & Int16(POLLNVAL) != 0 {
            throw POSIXError(.EBADF)
          }
          let count = read(descriptors[index], &buffer, buffer.count)
          if count == 0 { open[index] = false; pendingAtExit[index] = 0; continue }
          if count < 0 {
            if errno == EINTR || errno == EAGAIN { continue }
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
          }
          pendingAtExit[index] = max(0, pendingAtExit[index] - Int32(count))
          if index == 0 {
            guard count <= Self.standardOutputCaptureLimit - stdout.count else {
              throw CaptureError.standardOutputLimitExceeded(limit: Self.standardOutputCaptureLimit)
            }
            stdout.append(contentsOf: buffer.prefix(count))
          } else {
            guard count <= Self.standardErrorCaptureLimit - stderrSize else {
              throw CaptureError.standardErrorLimitExceeded(limit: Self.standardErrorCaptureLimit)
            }
            stderrSize += count
            var written = 0
            while written < count {
              let n = buffer.withUnsafeBytes { write(spool, $0.baseAddress!.advanced(by: written), count - written) }
              if n < 0 && errno == EINTR { continue }
              guard n > 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
              written += n
            }
          }
        }
      }
      child.waitUntilExit()
      finished = true
      try Task.checkCancellation()
      if child.terminationReason == .exit && child.terminationStatus == 0,
         String(data: stdout, encoding: .utf8) != nil { return (stdout, nil) }
      guard lseek(spool, 0, SEEK_SET) >= 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
      var stderr = Data()
      while true {
        try Task.checkCancellation()
        let count = read(spool, &buffer, buffer.count)
        if count == 0 { break }
        if count < 0 {
          if errno == EINTR { continue }
          throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
        stderr.append(contentsOf: buffer.prefix(count))
      }
      return (stdout, stderr)
    }
  }
}

private final class UnboundedStreamReads: @unchecked Sendable {
  private let lock = NSLock()
  private let process: Foundation.Process
  private var data: [Data?] = [nil, nil]
  private var error: (any Error)?

  init(process: Foundation.Process) { self.process = process }

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

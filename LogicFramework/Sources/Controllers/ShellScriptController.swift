import Combine
import Foundation

public protocol ShellScriptControlling {
  /// Run a Shellscript based on which `Source` is supplied.
  ///
  /// Source is a value-type that decided which type of Shellscript
  /// should be invoked. There are two types of script sources:
  ///
  /// `.inline` - A script that is embedded in the command
  /// `.path` - A script that is located on disk
  ///
  /// - Note: There is no safety mechanism in place to make sure
  ///         that destructive aren't performed inside a shellscript.
  ///         Hence the user needs to know what they are doing before
  ///         including any foreign scripts on their system.
  ///
  /// - Parameter source: A `Source` enum that decides how the
  ///                     Shellscript should be constructed
  /// - Returns: A publisher that wraps a result of the run operation.
  func run(_ source: ScriptCommand.Source) -> CommandPublisher
}

class ShellScriptController: ShellScriptControlling {
  let shellPath: String = "/bin/bash"

  func run(_ source: ScriptCommand.Source) -> CommandPublisher {
    let command: String
    switch source {
    case .inline(let inline):
      command = inline
    case .path(let path):
      let filePath = path.sanitizedPath
      command = """
      sh \(filePath)
      """
    }
    _ = Process().shell(command, shellPath: shellPath)
    return Result.success(()).publisher.eraseToAnyPublisher()
  }
}

private extension Process {
  func shell(_ command: String, shellPath: String) -> String {
    let outputPipe = Pipe()
    let errorPipe = Pipe()

    launchPath = shellPath
    arguments = ["-c", command]
    standardOutput = outputPipe
    standardError = errorPipe

    var data = Data()
    var error = Data()

    outputPipe.fileHandleForReading.readabilityHandler = { handler in
      data.append(handler.availableData)
    }

    errorPipe.fileHandleForReading.readabilityHandler = { handler in
      error.append(handler.availableData)
    }

    launch()
    waitUntilExit()

    outputPipe.fileHandleForReading.readabilityHandler = nil
    errorPipe.fileHandleForReading.readabilityHandler = nil

    let result = data.toString()

    return result
  }
}

fileprivate extension Data {
  func toString() -> String {
    guard let output = String(data: self, encoding: .utf8) else { return "" }

    guard !output.hasSuffix("\n") else {
      let endIndex = output.index(before: output.endIndex)
      return String(output[..<endIndex])
    }

    return output
  }
}

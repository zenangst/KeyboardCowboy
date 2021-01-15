import Combine
import Foundation
import ModelKit

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

final class ShellScriptController: ShellScriptControlling {
  func run(_ source: ScriptCommand.Source) -> CommandPublisher {
    Future { promise in
      let command: String
      switch source {
      case .inline(let inline):
        command = inline
        let error = NSError(domain: "com.zenangst.KeyboardCowboy.ShellScriptController",
                            code: -999, userInfo: [
                              NSLocalizedDescriptionKey: "Inline scripts is not supported yet."
                            ])
        promise(.failure(error))
        return
      case .path(let path):
        let filePath = path.sanitizedPath
        command = (filePath as NSString).lastPathComponent
        let url = URL(fileURLWithPath: (filePath as NSString).deletingLastPathComponent)

        let ctx = Process().shell(command, at: url)
        ctx.task.terminationHandler = { _ in
          let errorController = ctx.errorController

          if let errorMessage = errorController.string,
             !errorMessage.isEmpty {
            let error = NSError(domain: "com.zenangst.KeyboardCowboy.ShellScriptController",
                                code: -999, userInfo: [
                                  NSLocalizedDescriptionKey: errorMessage
                                ])
            Debug.print("🛑 Unable to run: \(source)")
            Debug.print("🛑 Error: \(error)")
            promise(.failure(error))
            return
          }

          promise(.success(()))
        }
      }
    }.eraseToAnyPublisher()
  }
}

private struct ProcessContext {
  let task: Process
  let outputController: OutputController
  let errorController: OutputController
}

private class OutputController {
  var string: String?
}

private extension Process {
  func shell(_ command: String, at url: URL) -> ProcessContext {
    let outputController = OutputController()
    let errorController = OutputController()
    let outputPipe = Pipe()
    let errorPipe = Pipe()

    launchPath = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
    arguments = ["-i", "-l", command]
    standardOutput = outputPipe
    standardError = errorPipe
    currentDirectoryURL = url

    var data = Data()
    var error = Data()

    do {
      try run()

      data = outputPipe.fileHandleForReading.readDataToEndOfFile()
      error = errorPipe.fileHandleForReading.readDataToEndOfFile()

      outputController.string = String(data: data, encoding: .utf8)
      errorController.string = String(data: error, encoding: .utf8)

      waitUntilExit()
    } catch let error {
      Debug.print("❌ \(error)")
    }

    return ProcessContext(task: self,
                          outputController: outputController,
                          errorController: errorController)
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

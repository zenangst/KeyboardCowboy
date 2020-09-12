import Foundation

public protocol ShellScriptControlling {
  func run(_ source: ScriptCommand.Source) -> String
}

class ShellScriptController: ShellScriptControlling {
  func run(_ source: ScriptCommand.Source) -> String {
    let command: String
    switch source {
    case .inline(let inline):
      command = inline
    case .path(let path):
      var filePath = path
      filePath = (filePath as NSString).expandingTildeInPath
      filePath = filePath.replacingOccurrences(of: "", with: "\\ ")
      command = """
      sh \(filePath)
      """
    }
    return Process().shell(command)
  }
}

extension Process {
  func shell(_ command: String) -> String {
    let outputPipe = Pipe()
    let errorPipe = Pipe()

    launchPath = "/bin/bash"
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

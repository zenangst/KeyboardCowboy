import Foundation

let rootFolder = URL(fileURLWithPath: #file).pathComponents
  .prefix(while: { $0 != "KeyboardCowboy" })
  .joined(separator: "/")
  .dropFirst()

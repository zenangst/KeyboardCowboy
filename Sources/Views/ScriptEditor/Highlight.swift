import Foundation

struct Highlight {
  let pattern: NSRegularExpression?
  let attributes: [NSAttributedString.Key : Any]

  init(_ pattern: String, attributes: [NSAttributedString.Key : Any]) {
    self.pattern = try? NSRegularExpression(pattern: pattern, options: .anchorsMatchLines)
    self.attributes = attributes
  }
}

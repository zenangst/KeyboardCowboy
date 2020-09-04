import Foundation

enum Rule {
  /// Activate when an application is front-most
  case application
  /// Only active during certain days
  /// TODO: This case needs a value to be passed in
  case days
  /// Active during certain times during the day
  /// TODO: This needs a value, preferably a range.
  case timespan
}

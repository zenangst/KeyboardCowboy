import Foundation

public struct Rule: Codable, Hashable {
  public let applications: [Application]
  public let days: [Day]

  init(applications: [Application] = [], days: [Day] = []) {
    self.applications = applications
    self.days = days
  }

  public enum Day: Int, Codable, Hashable {
    case monday = 0
    case tuesday = 1
    case wednesday = 2
    case thursday = 3
    case friday = 4
    case saturday = 5
    case sunday = 6
  }
}

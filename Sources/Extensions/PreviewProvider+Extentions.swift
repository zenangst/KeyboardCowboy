import SwiftUI

extension PreviewProvider {
  static var saloon: Saloon { Saloon() }

  static var applicationStore: ApplicationStore { saloon.applicationStore }
}

import SwiftUI

struct GroupViewModel: Hashable, Identifiable {
  let id: String
  let name: String
  let icon: IconViewModel?
  let color: String
  let symbol: String
  let count: Int
}

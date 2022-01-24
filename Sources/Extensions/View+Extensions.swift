import SwiftUI

extension View {
  @ViewBuilder
  func transform<Transform: View>(_ transform: (Self) -> Transform) -> some View {
    transform(self)
  }
}

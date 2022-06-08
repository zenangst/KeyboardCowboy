import SwiftUI

extension View {
  @ViewBuilder
  func transform<Transform: View>(_ transform: (Self) -> Transform) -> some View {
    transform(self)
  }

  func cursorOnHover(_ cursor: NSCursor) -> some View {
    onHover(perform: { hovering in
      if hovering { cursor.push() } else { NSCursor.pop() }
    })
  }

  @ViewBuilder
  func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
    if condition { transform(self) } else { self }
  }
}

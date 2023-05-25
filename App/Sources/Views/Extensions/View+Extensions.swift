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


  @ViewBuilder
  func debugEdit(_ file: StaticString = #file) -> some View {
    if launchArguments.isEnabled(.debugEditing) {
      DebugView(file: "\(file)", content: { self })
    } else {
      self
    }
  }

  @ViewBuilder
  func debugID<Element: Identifiable>(_ element: Element) -> some View where Element.ID == String {
    self
      .overlay(content: {
        Text(element.id)
          .foregroundColor(.black)
          .background(.yellow)
          .lineLimit(1)
          .minimumScaleFactor(0.7)
          .allowsHitTesting(false)
      })
  }

  func onFrameChange(space: CoordinateSpace = .global, perform: @escaping (CGRect) -> Void) -> some View {
    self
      .modifier(GeometryPreferenceKeyView<FramePreferenceKey>(space: space, transform: { $0.frame(in: space) }))
      .onPreferenceChange(FramePreferenceKey.self, perform: perform)
  }
}

struct DebugView<Content>: View where Content: View {
  @State var isHovered: Bool = false
  var file: String
  var content: () -> Content

  var body: some View {
    content()
      .popover(isPresented: $isHovered, content: popover)
      .onHover {
        guard NSEvent.modifierFlags.contains(.option) else { return }
        isHovered = $0
      }
  }

  private func popover() -> some View {
    ZStack(alignment: .leading) {
      VStack(alignment: .leading) {
        Text("File: ") + Text("\((file as NSString).lastPathComponent)").bold()

        HStack {
          Button(action: {
            Task {
              NSWorkspace.shared.open(URL(filePath: file))
            }
          }, label: {
            Text("Edit")
          })

          Button(action: {
            Task {
              NSWorkspace.shared.reveal(file)
            }
          }, label: {
            Text("Reveal")
          })
        }
      }
      .padding()
    }
    .buttonStyle(
      GradientButtonStyle(.init(nsColor: .systemIndigo))
    )
    .background(
      LinearGradient(colors: [
        Color(.black).opacity(0.8),
        Color(.black).opacity(0.95),
      ], startPoint: .top, endPoint: .bottom)
      .padding(-16)
    )
  }
}

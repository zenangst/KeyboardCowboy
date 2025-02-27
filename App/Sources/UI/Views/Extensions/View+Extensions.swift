import SwiftUI

extension View {
  @ViewBuilder
  func stacked(_ stacked: Binding<Bool>, color: Color, size: CGFloat) -> some View {
    let angle = Angle.degrees(stacked.wrappedValue ? 45 : 0)
    let cosineOfAngle = cos(angle.radians)
    let adjustmentFactor: CGFloat = 1.0
    let scale = (1.0 / cosineOfAngle) * adjustmentFactor
    self
      .rotation3DEffect(
        angle,
        axis: (x: 1, y: 0, z: 0)
      )
      .scaleEffect(x: scale, y: 1, anchor: .center)
      .animation(.easeInOut(duration: 3.0), value: stacked.wrappedValue)
  }

  func iconShape(_ size: CGFloat) -> some View {
    self
      .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
  }

  @ViewBuilder
  func iconOverlay() -> some View {
    IconOverlayView()
      .drawingGroup()
  }
  func iconBorder(_ size: CGFloat) -> some View {
    IconBorderView(size)
      .drawingGroup()
  }

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

  @MainActor @ViewBuilder
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

private struct IconBorderView: View {
  let size: CGFloat

  init(_ size: CGFloat) {
    self.size = size
  }

  var body: some View {
    LinearGradient(stops: [
      .init(color: Color(.white).opacity(0.15), location: 0.25),
      .init(color: Color(.black).opacity(0.25), location: 1.0),
    ], startPoint: .top, endPoint: .bottom)
    .mask {
      RoundedRectangle(cornerRadius: size * 0.2)
        .stroke(lineWidth: size * 0.025)
    }
  }
}

private struct IconOverlayView: View {
  var body: some View {
    AngularGradient(stops: [
      .init(color: Color.clear, location: 0.0),
      .init(color: Color.white.opacity(0.2), location: 0.2),
      .init(color: Color.clear, location: 1.0),
    ], center: .bottomLeading)

    LinearGradient(stops: [
      .init(color: Color.white.opacity(0.2), location: 0),
      .init(color: Color.clear, location: 0.3),
    ], startPoint: .top, endPoint: .bottom)

    LinearGradient(stops: [
      .init(color: Color.clear, location: 0.8),
      .init(color: Color(.windowBackgroundColor).opacity(0.3), location: 1.0),
    ], startPoint: .top, endPoint: .bottom)

    LinearGradient(stops: [
      .init(color: Color.clear, location: 0.5),
      .init(color: Color(.windowBackgroundColor).opacity(0.3), location: 1.0),
    ], startPoint: .top, endPoint: .bottom)
  }
}

@MainActor
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
    .background(
      LinearGradient(colors: [
        Color(.black).opacity(0.8),
        Color(.black).opacity(0.95),
      ], startPoint: .top, endPoint: .bottom)
      .padding(-16)
    )
  }
}

struct ViewExtensions_Previews: PreviewProvider {
  @State static var stacked: Bool = true
  static var previews: some View {
    VStack {
      HStack {
        WindowManagementIconView(size: 128)
        WindowManagementIconView(size: 64)
        WindowManagementIconView(size: 32)
      }
      HStack {
        WindowManagementIconView(size: 128)
        WindowManagementIconView(size: 64)
        WindowManagementIconView(size: 32)
      }

      VStack(spacing: 0) {
        UIElementIconView(size: 32)
        MenuIconView(size: 32)
        WindowManagementIconView(size: 32)
      }
      .background()
    }
    .onTapGesture {
      stacked.toggle()
    }
    .padding()
  }
}

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
}

private class DebugCommandKeyManager: ObservableObject {
  @Published var commandIsPressed: Bool = false

  init() {
    NSEvent.addLocalMonitorForEvents(matching: .flagsChanged, handler: commandKey)
  }

  func commandKey(_ event: NSEvent) -> NSEvent {
    if event.modifierFlags.contains(.command) {
      commandIsPressed = true
    } else {
      commandIsPressed = false
    }
    return event
  }
}

struct DebugView<Content>: View where Content: View {
  @StateObject private var manager: DebugCommandKeyManager = .init()
  @State var isHovered: Bool = false
  var file: String
  var content: () -> Content

  var body: some View {
    content()
      .overlay(content: {
        ZStack(alignment: .leading) {
          LinearGradient(colors: [
            Color(.black).opacity(0.8),
            Color(.black).opacity(0.95),
          ], startPoint: .top, endPoint: .bottom)
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
        .opacity(isHovered && manager.commandIsPressed ? 1 : 0)
        .buttonStyle(GradientButtonStyle(.init(nsColor: .systemIndigo)))
      })
      .onHover { isHovered = $0 }
  }
}

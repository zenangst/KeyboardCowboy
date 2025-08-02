import SwiftUI

extension View {
  @MainActor
  func designTime() -> some View {
   self
      .environmentObject(DesignTime.configurationsPublisher)
      .environmentObject(DesignTime.configurationPublisher)
      .environmentObject(DesignTime.contentPublisher)
      .environmentObject(DesignTime.detailStatePublisher)
      .environmentObject(DesignTime.groupsPublisher)
      .environmentObject(DesignTime.groupPublisher)
      .environmentObject(DesignTime.infoPublisher)
      .environmentObject(DesignTime.triggerPublisher)
      .environmentObject(DesignTime.commandsPublisher)
      .environmentObject(KeyShortcutRecorderStore())
      .environmentObject(ApplicationStore.shared)
      .environmentObject(ShortcutStore(ScriptCommandRunner()))
      .defaultStyle()
  }
}

public extension View {
  func viewDebugger(border: Bool = false) -> some View {
    self.modifier(ViewDebugger(border: border))
  }
}

struct ViewDebug_Preview: PreviewProvider {
  static var previews: some View {
    Text("Hello world!")
      .frame(width: 400, height: 400)
      .foregroundColor(.blue)
      .viewDebugger()
  }
}

public struct ViewDebugger: ViewModifier {
  private let border: Bool

  init(border: Bool) {
    self.border = border
  }

  public func body(content: Content) -> some View {
    if isRunningPreview {
      content
        .overlay(GeometryReader { proxy in
          VStack {
            HStack {
              Text("\(Int(proxy.size.width))x\(Int(proxy.size.height))")
                .font(.system(size: 16, weight: .regular, design: .monospaced))
                .padding(4)
                .foregroundColor(.black)
                .background(Color(.systemYellow).cornerRadius(6.0))
                .compositingGroup()
                .shadow(radius: 2, y: 1)
                .scaleEffect(0.6, anchor: .topLeading)
                .offset(x: 2, y: 2)
                .fixedSize()
              Spacer()
            }
            Spacer()
          }
          .background(
            ZStack {
              RoundedRectangle(cornerRadius: 6)
                .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [10], dashPhase: 10))
                .foregroundColor(Color(.black).opacity(0.5))
              RoundedRectangle(cornerRadius: 6)
                .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [10]))
                .foregroundColor(Color(.systemYellow))
            }
              .compositingGroup()
              .shadow(radius: 2, y: 1)
              .opacity(border ? 1 : 0)
          )
        })
    } else {
      content
    }
  }
}

import SwiftUI
import ModelKit

struct WorkflowListView: View {
  let workflow: Workflow
  @State private var isHovering: Bool = false

  var body: some View {
    VStack(alignment: .center, spacing: 0) {
      HStack(alignment: .center) {
        VStack(alignment: .leading, spacing: 3) {
          name
          HStack {
            numberOfCommands.font(.callout)
            keyboardShortcuts().font(.caption)
          }
        }.frame(height: 48)
        Spacer()
        icon
      }.padding(.leading, 10)
      Divider().opacity(0.33)
    }
  }
}

// MARK: - Subviews

private extension WorkflowListView {
  var name: some View {
    Text(workflow.name)
      .foregroundColor(.primary)
  }

  var numberOfCommands: some View {
    Group {
    if workflow.commands.count > 1 {
      Text("\(workflow.commands.count) commands")
    } else if workflow.commands.count > 0 {
      Text("\(workflow.commands.count) command")
    }
    }.foregroundColor(.secondary)
  }

  @ViewBuilder
  func keyboardShortcuts() -> some View {
    if !workflow.keyboardShortcuts.isEmpty {
      Divider().frame(height: 10)
    }
    ForEach(workflow.keyboardShortcuts) { shortcut in
      KeyboardShortcutView(shortcut: shortcut)
    }
  }

  var icon: some View {
    ZStack {
      ForEach(0..<workflow.commands.count, id: \.self) { index in
        let command = workflow.commands[index]
        let cgIndex = CGFloat(index)
        let multiplier = -cgIndex * 5
        let shadowRadius = max(cgIndex - 1, 0)
        let scale: CGFloat = isHovering
          ? workflow.commands.count > 1 ? 0.9 + ( 0.05 * cgIndex) : 1.0
          : 1.0

        IconView(path: command.icon).frame(width: 48, height: 48)
          .scaleEffect(scale, anchor: .center)
          .offset(x: isHovering ?  multiplier : 0,
                  y: isHovering ? multiplier : 0)
          .rotationEffect(.degrees( isHovering ? -Double(index) * 10 : 0 ))
          .shadow(color: Color(NSColor.black).opacity( isHovering ? 0.025 : 0.005),
                  radius: isHovering ? shadowRadius : 3,
                  x: isHovering ? -multiplier : 0,
                  y: isHovering ? -multiplier : 1)
          .onHover { value in
            withAnimation(.easeInOut(duration: 0.15)) {
              if isHovering != value { isHovering = value }
            }
          }
      }
    }
  }
}

// MARK: - Previews

struct WorkflowListView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    ForEach(ModelFactory().commands()) { command in
      WorkflowListView(workflow: ModelFactory().workflowCell(
        [command], name: command.name
      ))
    }
  }
}

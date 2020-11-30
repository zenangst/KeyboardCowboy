import SwiftUI
import ModelKit

struct WorkflowListCell: View {
  let workflow: Workflow
  @State var isHovering: Bool = false
  @EnvironmentObject var userSelection: UserSelection

  var body: some View {
    VStack(alignment: HorizontalAlignment.center, spacing: 0) {
      HStack {
        VStack(alignment: .leading) {
          name
          numberOfCommands
        }
        Spacer()
        icon
      }.padding(.leading, 10)
      Divider().opacity( userSelection.workflow == workflow ? 0 : 0.33)
    }.frame(height: 48)
  }
}

// MARK: - Subviews

private extension WorkflowListCell {
  var name: some View {
    Text(workflow.name)
      .foregroundColor(.primary)
  }

  var numberOfCommands: some View {
    Text("\(workflow.commands.count) commands")
      .foregroundColor(.secondary)
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

        IconView(icon: command.icon).frame(width: 48, height: 48)
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

struct WorkflowListCell_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    ForEach(ModelFactory().commands()) { command in
      WorkflowListCell(workflow: ModelFactory().workflowCell(
        [command], name: command.name
      )).environmentObject(UserSelection())
    }
  }
}

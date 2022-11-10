import SwiftUI

struct SingleDetailView: View {
  @ObserveInjection var inject
  @State var model: DetailViewModel

  init(_ model: DetailViewModel) {
    _model = .init(initialValue: model)
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading) {
        WorkflowInfoView($model)
          .padding([.leading, .trailing, .bottom], 8)

        Group {
          switch model.trigger {
          case .keyboardShortcuts:
            WorkflowShortcutsView()
          case .applications:
            Text("Application")
          case .none:
            WorkflowTriggerView()
          }
        }
        .padding([.leading, .trailing, .bottom], 8)
      }
      .padding()
      .background(Color(.textBackgroundColor))

      VStack(alignment: .leading, spacing: 0) {
        Label("Commands:", image: "")
          .padding([.leading, .trailing, .bottom], 8)
        EditableVStack(data: $model.commands, id: \.id, cornerRadius: 8) { command in
          CommandView(command)
        }
      }
      .padding()
    }
    .background(gradient)
    .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
    .labelStyle(HeaderLabelStyle())
    .enableInjection()
  }

  var gradient: some View {
    LinearGradient(
      gradient: Gradient(
        stops: [
          .init(color: Color(.windowBackgroundColor).opacity(0.25), location: 0.5),
          .init(color: Color(.gridColor).opacity(0.75), location: 1.0),
        ]),
      startPoint: .top,
      endPoint: .bottom)
  }
}



struct WorkflowTriggerView: View {
  @ObserveInjection var inject

  var body: some View {
    VStack(alignment: .leading) {
      Label("Add a trigger:", image: "")
      HStack {
        Button("Application", action: {})
        Button("Keyboard Shortcut", action: {})
        Spacer()
      }
    }
    .enableInjection()
  }
}

struct WorkflowInfoView: View {
  @ObserveInjection var inject
  @Binding var workflow: DetailViewModel

  init(_ workflow: Binding<DetailViewModel>) {
    _workflow = workflow
  }

  var body: some View {
    HStack {
      TextField("Workflow name", text: $workflow.name)
        .textFieldStyle(LargeTextFieldStyle())
      Spacer()
      Toggle("", isOn: $workflow.isEnabled)
        .toggleStyle(SwitchToggleStyle())
        .font(.callout)
    }
    .enableInjection()
  }
}

struct WorkflowShortcutsView: View {
  @ObserveInjection var inject

  var body: some View {
    VStack(alignment: .leading) {
      Label("Keyboard Shortcuts:", image: "")
      HStack {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack {
            ModifierKeyIcon(key: .function)
              .frame(width: 32)
            RegularKeyIcon(letter: "Space")
          }
          .padding([.leading, .top, .bottom], 6)
        }
        Spacer()
        Divider()
        Button(action: {},
               label: { Image(systemName: "plus") })
        .buttonStyle(KCButtonStyle())
        .font(.callout)
        .padding(.horizontal, 16)
      }
      .padding(4)
      .background(Color(.windowBackgroundColor))
      .cornerRadius(8)
      .shadow(color: Color(.shadowColor).opacity(0.15), radius: 3, x: 0, y: 1)
    }
    .enableInjection()
  }
}

struct CommandView: View {
  @ObserveInjection var inject
  @Binding var command: DetailViewModel.CommandViewModel

  init(_ command: Binding<DetailViewModel.CommandViewModel>) {
    _command = command
  }

  var body: some View {
    HStack {
      Text(command.name)
      Spacer()
      Toggle("", isOn: $command.isEnabled)
        .toggleStyle(.switch)
    }
    .padding(8)
    .background(.background)
    .cornerRadius(8)
    .enableInjection()
  }
}

struct SingleDetailView_Previews: PreviewProvider {
  static var previews: some View {
    SingleDetailView(DesignTime.detail)
  }
}

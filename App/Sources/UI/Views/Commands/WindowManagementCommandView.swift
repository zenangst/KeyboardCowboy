import SwiftUI

struct WindowManagementCommandView: View {
  enum Action {
    case onUpdate(CommandViewModel.Kind.WindowManagementModel)
    case commandAction(CommandContainerAction)
  }

  @Namespace var namespace
  @Binding var metaData: CommandViewModel.MetaData
  @State var model: CommandViewModel.Kind.WindowManagementModel
  @State var pixels: String

  private let onAction: (Action) -> Void

  init(_ metaData: Binding<CommandViewModel.MetaData>,
       model: CommandViewModel.Kind.WindowManagementModel,
       onAction: @escaping (Action) -> Void) {
    _metaData = metaData
    _model = .init(initialValue: model)
    self.onAction = onAction

    switch model.kind {
    case  .increaseSize(let value, _, _),
        .decreaseSize(let value, _, _),
        .move(let value, _, _):
      _pixels = .init(initialValue: String(value))
    default:
      _pixels = .init(initialValue: "0")
    }
  }

  var body: some View {
    CommandContainerView($metaData,
                         icon: {
      command in
      ZStack {
        switch model.kind {
        case  .increaseSize(_, let direction, _),
              .decreaseSize(_, let direction, _),
              .move(_, let direction, _):
          RoundedRectangle(cornerSize: .init(width: 8, height: 8))
            .stroke(Color.white.opacity(0.4), lineWidth: 2.0)
            .frame(width: 32, height: 32, alignment: .center)
            .background {
              RoundedRectangle(cornerSize: .init(width: 8, height: 8))
                .fill(Color(.controlAccentColor).opacity(0.375))
                .cornerRadius(8, antialiased: false)
            }
            .overlay(alignment: resolveAlignment(model.kind)) {
              RoundedRectangle(cornerSize: .init(width: 4, height: 4))
                .fill(Color.white)
                .frame(width: 10, height: 10)
                .overlay {
                  Image(systemName: direction.imageSystemName(increment: true))
                    .resizable()
                    .foregroundStyle(Color.black)
                    .frame(width: 6, height: 6)
                    .matchedGeometryEffect(id: "geometry-image-id", in: namespace)
                }
                .padding(4)
            }
            .matchedGeometryEffect(id: "geometry-container-id", in: namespace)
            .compositingGroup()
            .animation(.smooth, value: model.kind)
        case .fullscreen:
          ZStack {
            RoundedRectangle(cornerSize: .init(width: 8, height: 8))
              .fill(Color(.controlAccentColor).opacity(0.375))
              .cornerRadius(8, antialiased: false)
              .frame(width: 32, height: 32, alignment: .center)
            RoundedRectangle(cornerSize: .init(width: 8, height: 8))
              .stroke(Color.white.opacity(0.4), lineWidth: 2.0)
              .frame(width: 32, height: 32, alignment: .center)
            Image(systemName: "arrow.up.backward.and.arrow.down.forward")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 16, height: 16)
          }
        case .center:
          ZStack {
            RoundedRectangle(cornerSize: .init(width: 8, height: 8))
              .fill(Color(.controlAccentColor).opacity(0.375))
              .cornerRadius(8, antialiased: false)
              .frame(width: 32, height: 32, alignment: .center)
            RoundedRectangle(cornerSize: .init(width: 8, height: 8))
              .stroke(Color.white.opacity(0.4), lineWidth: 2.0)
              .frame(width: 32, height: 32, alignment: .center)
            Image(systemName: "camera.metering.center.weighted")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 16, height: 16)
          }
        case .moveToNextDisplay:
          ZStack {
            RoundedRectangle(cornerSize: .init(width: 8, height: 8))
              .fill(Color(.controlAccentColor).opacity(0.375))
              .cornerRadius(8, antialiased: false)
              .frame(width: 32, height: 32, alignment: .center)
            RoundedRectangle(cornerSize: .init(width: 8, height: 8))
              .stroke(Color.white.opacity(0.4), lineWidth: 2.0)
              .frame(width: 32, height: 32, alignment: .center)
            Image(systemName: "display")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 16, height: 16)
              .overlay {
                Image(systemName: "arrow.right.circle.fill")
                  .resizable()
                  .aspectRatio(contentMode: .fit)
                  .frame(width: 10, height: 10)
                  .offset(x: 10, y: 10)
              }
          }
        }
      }
    },
                         content: { _ in
      VStack(alignment: .leading) {
        Menu(content: {
          ForEach(WindowCommand.Kind.allCases) { kind in
            Button(kind.displayValue) {
              model.kind = kind
              onAction(.onUpdate(model))
            }
          }
        }, label: {
          Text(model.kind.displayValue)
        })
        .menuStyle(GradientMenuStyle(.init(nsColor: .gray), fixedSize: false))
        
        switch model.kind {
        case  .increaseSize(_, let direction, _),
              .decreaseSize(_, let direction, _),
              .move(_, let direction, _):

          HStack {
            let models = WindowCommand.Direction.allCases
            LazyVGrid(columns: (0..<3).map {
              _ in GridItem(.fixed(24), spacing: 1)
            },
                      alignment: .center,
                      spacing: 1,
                      content: {
              ForEach(Array(zip(models.indices, models)), id: \.1.id) { offset, element in
                if offset == 4 { Spacer() }
                Button {
                  let kind: WindowCommand.Kind
                  switch model.kind {
                  case .increaseSize(let value, _, let constrainedToScreen):
                    kind = .increaseSize(by: value, direction: element, constrainedToScreen: constrainedToScreen)
                  case .decreaseSize(let value, _, let constrainedToScreen):
                    kind = .decreaseSize(by: value, direction: element, constrainedToScreen: constrainedToScreen)
                  case .move(let value, _, let constrainedToScreen):
                    kind = .move(by: value, direction: element, constrainedToScreen: constrainedToScreen)
                  default:
                    return
                  }
                  model.kind = kind
                  onAction(.onUpdate(.init(id: metaData.id, kind: kind)))
                } label: {
                  Text(element.displayValue(increment: model.kind.isIncremental))
                }
                .buttonStyle(
                  .gradientStyle(
                    config: .init(nsColor: element == direction ? .systemGreen : .systemGray)
                  )
                )
              }
            })
            .fixedSize()
            HStack {
              IntegerTextField(text: $pixels, onValidChange: { newValue in
                guard let pixels = Int(newValue) else { return }
                let kind: WindowCommand.Kind
                switch model.kind {
                case .increaseSize(_, let direction, let constrainedToScreen):
                  kind = .increaseSize(by: pixels, direction: direction, constrainedToScreen: constrainedToScreen)
                case .decreaseSize(_, let direction, let constrainedToScreen):
                  kind = .decreaseSize(by: pixels, direction: direction, constrainedToScreen: constrainedToScreen)
                case .move(_, let direction, let constrainedToScreen):
                  kind = .move(by: pixels, direction: direction, constrainedToScreen: constrainedToScreen)
                default:
                  return
                }

                onAction(.onUpdate(.init(id: metaData.id, kind: kind)))
              })
              .textFieldStyle(AppTextFieldStyle())
              .frame(width: 64)
              .fixedSize()
              Text("pixels")
                .font(.caption)
            }
            .padding(.leading, 8)

          }
        case .fullscreen(let padding):
          HStack {
            Text("Padding:")
              .font(.caption)
            TextField("", text: .constant(String(padding)))
              .textFieldStyle(AppTextFieldStyle())
              .frame(width: 32)
              .fixedSize()
          }
          .padding(.leading, 8)
        default:
          EmptyView()
        }
        
      }
    },
                         subContent: { _ in }) {
      onAction(.commandAction($0))
    }
  }

  private func resolveAlignment(_ kind: WindowCommand.Kind) -> Alignment {
    switch kind {
    case .increaseSize(_, let direction, _),
        .decreaseSize(_, let direction, _),
        .move(_, let direction, _):
      switch direction {
      case .leading:
        return .leading
      case .topLeading:
        return .topLeading
      case .top:
        return .top
      case .topTrailing:
        return .topTrailing
      case .trailing:
        return .trailing
      case .bottomTrailing:
        return .bottomTrailing
      case .bottom:
        return .bottom
      case .bottomLeading:
        return .bottomLeading
      }
    case .fullscreen:
      return .center
    case .center:
      return .center
    case .moveToNextDisplay:
      return .center
    }
  }
}

struct WindowManagementCommandView_Previews: PreviewProvider {

  static var models: [(model: CommandViewModel, kind: WindowCommand.Kind)] = WindowCommand.Kind.allCases
    .map(DesignTime.windowCommand)

  static var previews: some View {
    VStack {
      ForEach(models, id: \.model) { container in
        WindowManagementCommandView(
          .constant(container.model.meta),
          model: .init(id: container.model.id, kind: container.kind)
        ) { _ in }
          .frame(maxHeight: 180)
        Divider()
      }
    }
    .padding()
    .designTime()
    .previewLayout(.sizeThatFits)
  }
}

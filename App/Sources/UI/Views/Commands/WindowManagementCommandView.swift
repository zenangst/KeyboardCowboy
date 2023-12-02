import Bonzai
import Inject
import SwiftUI

struct WindowManagementCommandView: View {
  @ObserveInjection var inject
  enum Action {
    case onUpdate(CommandViewModel.Kind.WindowManagementModel)
    case commandAction(CommandContainerAction)
  }

  @Namespace var namespace
  @State var metaData: CommandViewModel.MetaData
  @State var model: CommandViewModel.Kind.WindowManagementModel
  @State var padding: String
  @State var pixels: String
  @State var constrainToScreen: Bool

  private let onAction: (Action) -> Void

  init(_ metaData: CommandViewModel.MetaData,
       model: CommandViewModel.Kind.WindowManagementModel,
       onAction: @escaping (Action) -> Void) {
    _metaData = .init(initialValue: metaData)
    _model = .init(initialValue: model)
    self.onAction = onAction

    switch model.kind {
    case  .increaseSize(let value, _, let padding, let constrainedToScreen),
        .move(let value, _, let padding, let constrainedToScreen):
      _pixels = .init(initialValue: String(value))
      _constrainToScreen = .init(initialValue: constrainedToScreen)
      _padding = .init(initialValue: String(padding))
    case .decreaseSize(let value, _, let constrainedToScreen):
      _pixels = .init(initialValue: String(value))
      _constrainToScreen = .init(initialValue: constrainedToScreen)
      _padding = .init(initialValue: "0")
    case .fullscreen(let padding):
      _padding = .init(initialValue: String(padding))
      _pixels = .init(initialValue: "0")
      _constrainToScreen = .init(initialValue: true)
    case .anchor(_, let padding):
      _padding = .init(initialValue: String(padding))
      _pixels = .init(initialValue: String(padding))
      _constrainToScreen = .init(initialValue: false)
    default:
      _padding = .init(initialValue: "0")
      _pixels = .init(initialValue: "0")
      _constrainToScreen = .init(initialValue: true)
    }
  }

  var body: some View {
    CommandContainerView($metaData,
                         icon: {
      command in
      ZStack {
        switch model.kind {
        case  .increaseSize(_, let direction, _, _),
              .decreaseSize(_, let direction, _),
              .move(_, let direction, _, _),
              .anchor(let direction, _):
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
            .animation(.easeInOut, value: model.kind)
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
      VStack(alignment: .leading, spacing: 8) {
        Menu(content: {
          ForEach(WindowCommand.Kind.allCases) { kind in
            Button(action: {
              model.kind = kind
              onAction(.onUpdate(model))
            }, label: {
              Image(systemName: kind.symbol)
              Text(kind.displayValue)
                .font(.subheadline)
            })
          }
        }, label: {
          Image(systemName: model.kind.symbol)
          Text(model.kind.displayValue)
            .font(.subheadline)
        })
        .menuStyle(.regular)

        switch model.kind {
        case  .increaseSize(_, let direction, _, _),
              .decreaseSize(_, let direction, _),
              .move(_, let direction, _, _),
              .anchor(let direction, _):
          HStack(spacing: 16) {
            let models = WindowCommand.Direction.allCases
            LazyVGrid(columns: (0..<3).map {
              _ in GridItem(.fixed(24), spacing: 1)
            },
                      alignment: .center,
                      spacing: 2,
                      content: {
              ForEach(Array(zip(models.indices, models)), id: \.1.id) { offset, element in
                if offset == 4 {
                  Image(systemName: "macwindow")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 12, height: 12)
                    .foregroundColor(.white)
                }
                Button {
                  let kind: WindowCommand.Kind
                  switch model.kind {
                  case .increaseSize(let value, _, let padding, let constrainedToScreen):
                    kind = .increaseSize(by: value, direction: element, padding: padding, constrainedToScreen: constrainedToScreen)
                  case .decreaseSize(let value, _, let constrainedToScreen):
                    kind = .decreaseSize(by: value, direction: element, constrainedToScreen: constrainedToScreen)
                  case .move(let value, _, let padding, let constrainedToScreen):
                    kind = .move(by: value, direction: element, padding: padding, constrainedToScreen: constrainedToScreen)
                  case .anchor(_, let padding):
                    kind = .anchor(position: element, padding: padding)
                  default:
                    return
                  }
                  model.kind = kind
                  onAction(.onUpdate(.init(id: metaData.id, kind: kind, animationDuration: model.animationDuration)))
                } label: {
                  Text(element.displayValue(increment: model.kind.isIncremental))
                    .frame(width: 10, height: 14)
                    .font(.subheadline)
                }
                .buttonStyle(
                  .zen(.init(color: element == direction ? .systemGreen : .systemGray))
                )
              }
            })
            .fixedSize()

            VStack(alignment: .leading) {
              HStack {
                if case .anchor = model.kind {
                  EmptyView()
                } else if case .decreaseSize = model.kind {
                    EmptyView()
                } else {
                  IntegerTextField(text: $pixels,
                                   onValidChange: { newValue in
                    guard let pixels = Int(newValue) else { return }
                    let kind: WindowCommand.Kind
                    switch model.kind {
                    case .increaseSize(_, let direction, let padding, let constrainedToScreen):
                      kind = .increaseSize(
                        by: pixels,
                        direction: direction,
                        padding: padding,
                        constrainedToScreen: constrainedToScreen
                      )
                    case .decreaseSize(_, let direction, let constrainedToScreen):
                      kind = .decreaseSize(
                        by: pixels,
                        direction: direction,
                        constrainedToScreen: constrainedToScreen
                      )
                    case .move(_, let direction, let padding, let constrainedToScreen):
                      kind = .move(
                        by: pixels,
                        direction: direction,
                        padding: padding,
                        constrainedToScreen: constrainedToScreen
                      )
                    case .anchor(let position, _):
                      kind = .anchor(position: position, padding: pixels)
                    default:
                      return
                    }
                    model.kind = kind
                    onAction(.onUpdate(.init(id: metaData.id, kind: kind, animationDuration: model.animationDuration)))
                  })
                  .textFieldStyle(.regular(Color(.windowBackgroundColor)))
                  .frame(width: 32)
                  .fixedSize()
                  Text("Pixels")
                    .font(.caption)
                }

                IntegerTextField(text: $padding,
                                 onValidChange: { newValue in
                  guard let padding = Int(newValue) else { return }
                  let kind: WindowCommand.Kind
                  switch model.kind {
                  case .increaseSize(let pixels, let direction, _, let constrainedToScreen):
                    kind = .increaseSize(
                      by: pixels,
                      direction: direction,
                      padding: padding,
                      constrainedToScreen: constrainedToScreen
                    )
                  case .decreaseSize(let pixels, let direction, let constrainedToScreen):
                    kind = .decreaseSize(
                      by: pixels,
                      direction: direction,
                      constrainedToScreen: constrainedToScreen
                    )
                  case .move(let pixels, let direction, _, let constrainedToScreen):
                    kind = .move(
                      by: pixels,
                      direction: direction,
                      padding: padding,
                      constrainedToScreen: constrainedToScreen
                    )
                  case .anchor(let position, _):
                    kind = .anchor(position: position, padding: padding)
                  default:
                    return
                  }
                  model.kind = kind
                  onAction(.onUpdate(.init(id: metaData.id, kind: kind, animationDuration: model.animationDuration)))
                })
                .textFieldStyle(.regular(Color(.windowBackgroundColor)))
                .frame(width: 32)
                .fixedSize()
                Text("Padding")
                  .font(.caption)
              }

              if case .anchor = model.kind {
                EmptyView()
              } else {
                ZenCheckbox(
                  "Constrain to screen bounds",
                  style: .small,
                  isOn: $constrainToScreen
                ) { constrainedToScreen in
                  let kind: WindowCommand.Kind
                  switch model.kind {
                  case .increaseSize(let pixels, let direction, let padding, _):
                    kind = .increaseSize(
                      by: pixels,
                      direction: direction,
                      padding: padding,
                      constrainedToScreen: constrainedToScreen
                    )
                  case .decreaseSize(let pixels, let direction, _):
                    kind = .decreaseSize(
                      by: pixels,
                      direction: direction,
                      constrainedToScreen: constrainedToScreen
                    )
                  case .move(let pixels, let direction, let padding, _):
                    kind = .move(
                      by: pixels,
                      direction: direction,
                      padding: padding,
                      constrainedToScreen: constrainedToScreen
                    )
                  case .anchor(let position, let padding):
                    kind = .anchor(position: position, padding: padding)
                  default:
                    return
                  }
                  model.kind = kind
                  onAction(.onUpdate(.init(id: metaData.id, kind: kind, animationDuration: model.animationDuration)))
                }
                .font(.caption)
              }
            }
            
          }
        case .fullscreen:
          HStack {
            Text("Padding:")
              .font(.caption)
            IntegerTextField(text: $padding, onValidChange: { newValue in
              guard let newPadding = Int(newValue) else { return }
              let kind: WindowCommand.Kind
              switch model.kind {
              case .fullscreen:
                kind = .fullscreen(padding: newPadding)
              default:
                return
              }
              model.kind = kind
              onAction(.onUpdate(.init(id: metaData.id, kind: kind, animationDuration: model.animationDuration)))
            })
            .textFieldStyle(.regular(Color(.windowBackgroundColor)))
            .frame(width: 32)
            .fixedSize()
          }
          .padding(.leading, 8)
        default:
          EmptyView()
        }
        
      }
    },
                         subContent: { _ in
      WindowManagementAnimationDurationView(windowCommand: $model) { newDuration in
        model.animationDuration = newDuration
        onAction(.onUpdate(.init(id: metaData.id, kind: model.kind, animationDuration: newDuration)))
      }
    },
                         onAction: {
      onAction(.commandAction($0))
    })
    .enableInjection()
  }

  private func resolveAlignment(_ kind: WindowCommand.Kind) -> Alignment {
    switch kind {
    case .increaseSize(_, let direction, _, _),
        .decreaseSize(_, let direction, _),
        .move(_, let direction, _, _),
        .anchor(let direction, _):
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
          container.model.meta,
          model: .init(id: container.model.id, kind: container.kind, animationDuration: 0)
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

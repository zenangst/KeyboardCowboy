import Bonzai
import Inject
import SwiftUI

struct WindowManagementCommandView: View {
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction

  @State private var model: CommandViewModel.Kind.WindowManagementModel

  private let metaData: CommandViewModel.MetaData
  private let iconSize: CGSize

  init(_ metaData: CommandViewModel.MetaData,
       model: CommandViewModel.Kind.WindowManagementModel,
       iconSize: CGSize) {
    _model = .init(initialValue: model)
    self.metaData = metaData
    self.iconSize = iconSize
  }

  var body: some View {
    CommandContainerView(
      metaData,
      placeholder: model.placeholder,
      icon: { WindowManagementIconView(size: iconSize.width) },
      content: {
        WindowManagementCommandInternalView(metaData, model: model, iconSize: iconSize)
      },
      subContent: {
        HStack {
          Spacer()
          WindowManagementAnimationDurationView(windowCommand: $model) { newDuration in
            model.animationDuration = newDuration
            updater.modifyCommand(withID: metaData.id, using: transaction) { command in
              guard case .windowManagement(var windowCommand) = command else { return }
              windowCommand.animationDuration = newDuration
              command = .windowManagement(windowCommand)
            }
          }
        }
      })
  }
}

struct WindowManagementCommandInternalView: View {
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction
  @Namespace var namespace
  @State var metaData: CommandViewModel.MetaData
  @State var model: CommandViewModel.Kind.WindowManagementModel
  @State var padding: String
  @State var pixels: String
  @State var constrainToScreen: Bool

  private let iconSize: CGSize

  init(_ metaData: CommandViewModel.MetaData,
       model: CommandViewModel.Kind.WindowManagementModel,
       iconSize: CGSize) {
    _metaData = .init(initialValue: metaData)
    _model = .init(initialValue: model)
    self.iconSize = iconSize

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
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        illustrationIcon()
        Menu(content: {
          ForEach(WindowManagementCommand.Kind.allCases) { kind in
            Button(action: {
              model.kind = kind
              performUpdate(kind)
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
      }

      switch model.kind {
      case .increaseSize, .decreaseSize,
           .move, .anchor:
        HStack(spacing: 16) {
          let models = WindowManagementCommand.Direction.allCases
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
                let kind: WindowManagementCommand.Kind
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
                performUpdate(kind)
              } label: {
                Text(element.displayValue(increment: model.kind.isIncremental))
                  .frame(width: 10, height: 14)
                  .font(.subheadline)
              }
            }
          })
          .fixedSize()

          Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
            if case .anchor = model.kind {
              GridRow {
                EmptyView()
                EmptyView()
              }
            } else {
              GridRow {
                NumberTextField(text: $pixels, onValidChange: { newValue in
                  guard let pixels = Int(newValue) else { return }
                  let kind: WindowManagementCommand.Kind
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
                  performUpdate(kind)
                })
                .fixedSize()
                Text("Pixels")
                  .font(.caption)
              }
            }

            GridRow {
              NumberTextField(text: $padding,
                              onValidChange: { newValue in
                guard let padding = Int(newValue) else { return }
                let kind: WindowManagementCommand.Kind
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
                performUpdate(kind)
              })
              .fixedSize()
              Text("Padding").font(.caption)
            }

            GridRow {
              if case .anchor = model.kind {
                EmptyView()
                EmptyView()
              } else {

                Toggle(isOn: $constrainToScreen, label: {})
                  .onChange(of: constrainToScreen) { constrainedToScreen in
                    let kind: WindowManagementCommand.Kind
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
                    performUpdate(kind)
                  }

                Text("Constrain to Screen")
              }
            }
          }
        }
      case .fullscreen:
        HStack(spacing: 12) {
          NumberTextField(text: $padding, onValidChange: { newValue in
            guard let newPadding = Int(newValue) else { return }
            let kind: WindowManagementCommand.Kind
            switch model.kind {
            case .fullscreen:
              kind = .fullscreen(padding: newPadding)
            default:
              return
            }
            model.kind = kind
            performUpdate(kind)
          })
          .fixedSize()
          Text("Padding")
        }
      default:
        EmptyView()
      }
    }

  }

  private func performUpdate(_ newKind: WindowManagementCommand.Kind) {
    updater.modifyCommand(withID: metaData.id, using: transaction) { command in
      guard case .windowManagement(var windowCommand) = command else { return }
      windowCommand.kind = newKind
      command = .windowManagement(windowCommand)
    }
  }

  private func resolveAlignment(_ kind: WindowManagementCommand.Kind) -> Alignment {
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

  func illustrationIcon() -> some View {
    ZStack {
      switch model.kind {
      case  .increaseSize(_, let direction, _, _),
          .decreaseSize(_, let direction, _),
          .move(_, let direction, _, _),
          .anchor(let direction, _):
        RoundedRectangle(cornerSize: .init(width: 4, height: 4))
          .stroke(Color(.controlAccentColor).opacity(0.475), lineWidth: 1)
          .padding(1)
          .overlay(alignment: resolveAlignment(model.kind)) {
            RoundedRectangle(cornerSize: .init(width: 4, height: 4))
              .fill(Color.white)
              .frame(width: iconSize.width / 2.75,
                     height: iconSize.height / 2.75)
              .overlay {
                Image(systemName: direction.imageSystemName(increment: true))
                  .resizable()
                  .foregroundStyle(Color.black)
                  .frame(width: 4, height: 4)
                  .matchedGeometryEffect(id: "geometry-image-id", in: namespace)
              }
              .padding(2)
          }
          .matchedGeometryEffect(id: "geometry-container-id", in: namespace)
          .compositingGroup()
          .animation(.easeInOut, value: model.kind)
      case .fullscreen:
        ZStack {
          RoundedRectangle(cornerSize: .init(width: 4, height: 4))
            .stroke(Color(.controlAccentColor).opacity(0.475), lineWidth: 1)
            .frame(width: iconSize.width, height: iconSize.height, alignment: .center)
          Image(systemName: "arrow.up.backward.and.arrow.down.forward")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: iconSize.width / 2, height: iconSize.height / 2)
        }
      case .center:
        ZStack {
          RoundedRectangle(cornerSize: .init(width: 4, height: 4))
            .stroke(Color(.controlAccentColor).opacity(0.475), lineWidth: 1)
          Image(systemName: "camera.metering.center.weighted")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: iconSize.width / 2, height: iconSize.height / 2)
        }
      case .moveToNextDisplay:
        ZStack {
          RoundedRectangle(cornerSize: .init(width: 4, height: 4))
            .stroke(Color(.controlAccentColor).opacity(0.475), lineWidth: 1)
          Image(systemName: "display")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: iconSize.width / 2, height: iconSize.height / 2)
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
    .frame(width: 24, height: 24)
  }
}

struct WindowManagementCommandView_Previews: PreviewProvider {
  @MainActor
  static var models: [(model: CommandViewModel, kind: WindowManagementCommand.Kind)] = WindowManagementCommand.Kind.allCases
    .map { kind in
      DesignTime.windowCommand(kind)
    }

  static var previews: some View {
    ScrollView {
      ForEach(models, id: \.model) { container in
        WindowManagementCommandView(
          container.model.meta,
          model: .init(
            id: container.model.id,
            kind: container.kind,
            animationDuration: 0
          ), iconSize: .init(width: 24, height: 24)
        )
        Divider()
      }
    }
    .frame(height: 1024)
    .padding()
    .designTime()
  }
}

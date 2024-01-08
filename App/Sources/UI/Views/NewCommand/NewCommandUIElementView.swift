import Bonzai
import SwiftUI

struct NewCommandUIElementView: View {
  @EnvironmentObject var captureStore: UIElementCaptureStore
  @Binding var payload: NewCommandPayload
  @Binding var validation: NewCommandValidation
  @State var predicates: [UIElementCommand.Predicate] = []
  @Namespace var namespace

  init(_ payload: Binding<NewCommandPayload>, validation: Binding<NewCommandValidation>) {
    _payload = payload
    _validation = validation
  }

  var body: some View {
    VStack {
      ScrollView {
        HStack {
          ZenLabel("UI Element")
            .frame(maxWidth: .infinity, alignment: .leading)
          Spacer()
          if !predicates.isEmpty {
            captureButton()
          }
        }
        .padding(.vertical, 8)

        if predicates.isEmpty {
          VStack {
            Text("Start recording and then click on the UI Element you want to capture while holding the ⌘-Command key.")
              .frame(maxWidth: 320)
            captureButton()
          }
          .multilineTextAlignment(.center)
          .frame(maxWidth: .infinity)
          .padding()
          .background()
          .clipShape(RoundedRectangle(cornerRadius: 8))
        }

        ForEach(predicates.indices, id: \.self) { index in
          Grid(alignment: .trailing, horizontalSpacing: 0, verticalSpacing: 6) {
            GridRow {
              Text("Value:")
              HStack {
                Menu {
                  ForEach(UIElementCommand.Predicate.Compare.allCases, id: \.displayName) { compare in
                    Button(action: { predicates[index].compare = compare },
                           label: {
                      Text(compare.displayName)
                        .font(.callout)
                    })
                  }
                } label: {
                  Text(predicates[index].compare.displayName)
                    .font(.caption)
                }
                .fixedSize()
                .menuStyle(.regular)

                TextField("", text: $predicates[index].value)
                  .textFieldStyle(.regular(Color(.windowBackgroundColor)))


                Button(action: {
                  withAnimation {
                    guard index < predicates.count else { return }
                    _ = self.predicates.remove(at: index)
                  }
                }, label: {
                  Image(systemName: "xmark")
                    .symbolRenderingMode(.palette)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 10, height: 10)
                })
                .padding(.top, 2)
                .buttonStyle(.zen(.init(calm: true, color: .systemRed,
                                        focusEffect: .constant(true),
                                        hoverEffect: .constant(true))))
              }
            }
            .padding([.top, .horizontal], 8)

            ZenDivider()

            GridRow {
              Text("Type:")
              HStack {
                Menu {
                  ForEach(UIElementCommand.Kind.allCases, id: \.displayName) { kind in
                    Button(action: { predicates[index].kind = kind },
                           label: {
                      Text(kind.displayName)
                        .font(.callout)
                    })
                  }
                } label: {
                  Text(predicates[index].kind.displayName)
                    .font(.caption)
                }
                .menuStyle(.regular)

                ForEach(UIElementCommand.Predicate.Properties.allCases) { property in
                  HStack {
                    ZenCheckbox(
                      isOn: Binding<Bool>(
                        get: { predicates[index].properties.contains(property) },
                        set: {
                          if $0 {
                            predicates[index].properties.append(property)
                          } else {
                            predicates[index].properties.removeAll(where: { $0 == property })
                          }
                        }
                      )
                    )
                    Text(property.displayName)
                      .font(.caption)
                      .lineLimit(1)
                      .truncationMode(.tail)
                      .allowsTightening(true)
                  }
                }
              }
            }
            .padding([.bottom, .horizontal], 8)
          }
          .background()
          .clipShape(RoundedRectangle(cornerRadius: 12))
        }
      }

      if let element = captureStore.capturedElement {
        Grid(alignment: .trailing, horizontalSpacing: 16, verticalSpacing: 4) {
          GridRow {
            Text("Identifier:")
              .font(.system(.caption, design: .monospaced))
              .foregroundColor(.secondary)
            Text(element.identifier ?? "No identifier")
              .frame(maxWidth: .infinity, alignment: .leading)
            Text("Description:")
              .font(.system(.caption, design: .monospaced))
              .foregroundColor(.secondary)
            Text(element.description ?? "No description")
              .frame(maxWidth: .infinity, alignment: .leading)
          }

          GridRow {
            Text("Title:")
              .font(.system(.caption, design: .monospaced))
              .foregroundColor(.secondary)
            Text(element.title ?? "No title")
              .frame(maxWidth: .infinity, alignment: .leading)
            Text("Value:")
              .font(.system(.caption, design: .monospaced))
              .foregroundColor(.secondary)
            Text(element.value ?? "No value")
              .frame(maxWidth: .infinity, alignment: .leading)
          }

          GridRow {
            Text("Role:")
              .font(.system(.caption, design: .monospaced))
              .foregroundColor(.secondary)
            Text(element.role ?? "No value")
              .frame(maxWidth: .infinity, alignment: .leading)
          }
        }
        .padding(8)
        .roundedContainer(padding: 8, margin: 2)
      }
    }

    .onReceive(captureStore.$capturedElement, perform: { element in
      guard let element else { return }

      var predicate = UIElementCommand.Predicate(value: "")

      let value = element.value
      ?? element.identifier
      ?? element.description
      ?? element.title
      ?? ""
      predicate.value = value

      if element.value != nil {
        predicate.properties = [.value]
      } else if element.identifier != nil {
        predicate.properties = [.identifier]
      } else if element.description != nil {
        predicate.properties = [.description]
      } else if element.title != nil {
        predicate.properties = [.title]
      }

      if let role = element.role {
        predicate.kind = UIElementCommand.Kind(role)
      }

      withAnimation {
        predicates.append(predicate)
        validation = updateAndValidatePayload()
      }
    })
    .onDisappear {
      captureStore.stopCapturing()
    }
  }

  private func captureButton() -> some View {
    Button(action: {
      captureStore.toggleCapture()
    }, label: {
      HStack {
        Image(systemName: captureStore.isCapturing ? "stop.circle" : "record.circle.fill")
          .symbolRenderingMode(.palette)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .foregroundStyle(
            captureStore.isCapturing ? Color(.white) : Color(.systemGreen).opacity(0.8),
            captureStore.isCapturing ? Color(.systemGreen) : Color(nsColor: .darkGray)
          )
          .animation(.smooth, value: captureStore.isCapturing)
          .frame(width: 14, height: 14)
          .padding(1)
        Text( captureStore.isCapturing ? "Stop Capture" : "Capture UI Element")
      }
    })
    .buttonStyle(
      .zen(
        .init(
          color: .systemGreen,
          hoverEffect: .constant(false)
        )
      )
    )
    .matchedGeometryEffect(id: "CaptureButton", in: namespace)
  }

  @discardableResult
  private func updateAndValidatePayload() -> NewCommandValidation {
    guard !predicates.filter({ !$0.value.isEmpty }).isEmpty else {
      return .invalid(reason: "You need a value to match.")
    }
    payload = .uiElement(predicates: predicates)
    return .valid
  }
}

#Preview("Empty") {
  NewCommandUIElementView(.readonly(.uiElement(predicates: [])), validation: .readonly(.needsValidation))
    .padding()
    .environmentObject(
      UIElementCaptureStore(
        isCapturing: false,
        capturedElement: nil
      )
    )
}

#Preview("Captured UI Element") {
  NewCommandUIElementView(.readonly(.uiElement(predicates: [])), validation: .readonly(.needsValidation))
    .padding()
    .environmentObject(
      UIElementCaptureStore(
        isCapturing: false,
        capturedElement: .init(description: nil, identifier: nil, title: nil, value: nil, role: nil)
      )
    )
}

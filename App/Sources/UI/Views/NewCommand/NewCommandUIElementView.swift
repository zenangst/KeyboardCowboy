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
          HStack(alignment: .top) {
            UIElementIconView(size: 24)
            Text("Start recording and then click on the UI Element you want to capture while holding the ⌘-Command key.")
              .frame(maxWidth: 320, alignment: .leading)
            captureButton()
          }
          .frame(maxWidth: .infinity)
          .padding()
          .roundedContainer(padding: 0, margin: 8)
        }

        ForEach(predicates.indices, id: \.self) { index in
          Grid(alignment: .trailing, horizontalSpacing: 0, verticalSpacing: 6) {
            GridRow {
              Text("Value:")
              HStack {
                Menu {
                  ForEach(UIElementCommand.Predicate.Compare.allCases, id: \.displayName) { compare in
                    Button(action: {
                      predicates[index].compare = compare
                      validation = updateAndValidatePayload()
                    },
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
                  .onChange(of: predicates[index].value, perform: { value in
                    validation = updateAndValidatePayload()
                  })


                Button(action: {
                  withAnimation {
                    guard index < predicates.count else { return }
                    _ = self.predicates.remove(at: index)
                  }
                  validation = updateAndValidatePayload()
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
                    Button(action: {
                      predicates[index].kind = kind
                      validation = updateAndValidatePayload()
                    },
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
                          validation = updateAndValidatePayload()
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
          .roundedContainer(padding: 0, margin: 8)
        }
      }

      if let element = captureStore.capturedElement {
        let predicatesCount = predicates.count - 1

        VStack(alignment: .leading, spacing: 0) {
          HStack {
            UIElementIconView(size: 24)
            Text("Captured Element")
          }
          .padding(8)
          ZenDivider(.horizontal)
          Grid(alignment: .trailing, horizontalSpacing: 16, verticalSpacing: 4) {
            GridRow {
              Text("Identifier:")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
              Button(action: {
                if let identifier = element.identifier {
                  predicates[predicatesCount].value = identifier
                  predicates[predicatesCount].properties = [.identifier]
                  validation = updateAndValidatePayload()
                }
              }) {
                Text(element.identifier ?? "No identifier")
                  .frame(maxWidth: .infinity, alignment: .leading)
              }

              Text("Description:")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)

              Button(action: {
                if let description = element.description {
                  predicates[predicatesCount].value = description
                  predicates[predicatesCount].properties = [.description]
                  validation = updateAndValidatePayload()
                }
              }) {
                Text(element.description ?? "No description")
                  .frame(maxWidth: .infinity, alignment: .leading)
              }
            }

            GridRow {
              Text("Title:")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
              Button(action: {
                if let title = element.title {
                  predicates[predicatesCount].value = title
                  predicates[predicatesCount].properties = [.title]
                  validation = updateAndValidatePayload()
                }
              }) {
                Text(element.title ?? "No title")
                  .frame(maxWidth: .infinity, alignment: .leading)
              }
              Text("Value:")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
              Button(action: {
                if let value = element.value {
                  predicates[predicatesCount].value = value
                  predicates[predicatesCount].properties = [.value]
                  validation = updateAndValidatePayload()
                }
              }) {
                Text(element.value ?? "No value")
                  .frame(maxWidth: .infinity, alignment: .leading)
              }
            }

            GridRow {
              Text("Role:")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
              Button(action: {
                if let role = element.role {
                  let kind = UIElementCommand.Kind(role)
                  predicates[predicatesCount].kind = kind
                  validation = updateAndValidatePayload()
                }
              }) {
                Text(element.role ?? "No value")
                  .frame(maxWidth: .infinity, alignment: .leading)
              }
              Text("Subrole:")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
              Button(action: {
                if let subrole = element.subrole {
                  predicates[predicatesCount].value = subrole
                  predicates[predicatesCount].properties = [.subrole]
                  validation = updateAndValidatePayload()
                }
              }) {
                Text(element.subrole ?? "No value")
                  .frame(maxWidth: .infinity, alignment: .leading)
              }
            }
          }
          .padding(8)
        }
        .roundedContainer(padding: 0, margin: 0)
        .padding(8)
        .buttonStyle(
          .zen(
            .init(
              calm: true,
              color: .systemGreen,
              backgroundColor: .clear,
              focusEffect: .constant(true),
              grayscaleEffect: .constant(true),
              hoverEffect: .constant(true),
              padding: .init(horizontal: .medium, vertical: .small),
              unfocusedOpacity: 0.5
            )
          )
        )
      }
    }

    .onReceive(captureStore.$capturedElement, perform: { element in
      guard let element else { return }

      var predicate = UIElementCommand.Predicate(value: "")

      if let elementValue = element.value, !elementValue.isEmpty {
        predicate.properties = [.value]
        predicate.value = elementValue
      } else if let elementIdentifier = element.identifier, !elementIdentifier.isEmpty {
        predicate.properties = [.identifier]
        predicate.value = elementIdentifier
      } else if let elementDescription = element.description, !elementDescription.isEmpty {
        predicate.properties = [.description]
        predicate.value = elementDescription
      } else if let elementTitle = element.title, !elementTitle.isEmpty {
        predicate.properties = [.title]
        predicate.value = elementTitle
      } else if let elementSubrole = element.subrole, !elementSubrole.isEmpty {
        predicate.properties = [.subrole]
        predicate.value = elementSubrole
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

#if DEBUG
#Preview("Empty") {
  NewCommandUIElementView(.readonly { .uiElement(predicates: []) }, validation: .readonly { .needsValidation })
    .padding()
    .environmentObject(
      UIElementCaptureStore(
        isCapturing: false,
        capturedElement: nil
      )
    )
}

#Preview("Captured UI Element") {
  NewCommandUIElementView(.readonly { .uiElement(predicates: []) }, validation: .readonly {.needsValidation })
    .padding()
    .environmentObject(
      UIElementCaptureStore(
        isCapturing: false,
        capturedElement: .init(description: nil, identifier: "foo", title: nil, value: nil, role: nil, subrole: nil)
      )
    )
}
#endif

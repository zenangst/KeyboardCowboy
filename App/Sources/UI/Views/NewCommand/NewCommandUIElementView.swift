import Bonzai
import Inject
import SwiftUI

struct NewCommandUIElementView: View {
  @ObserveInjection var inject
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

        if predicates.isEmpty {
          VStack {
            HStack {
              UIElementIconView(size: 24)
              Text("Start recording and then click on the UI Element you want to capture while holding the ⌘-key.")
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            captureButton()
          }
          .frame(maxWidth: .infinity)
          .roundedStyle(padding: 8)
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

                TextField("", text: $predicates[index].value)
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
                .buttonStyle(.destructive)
              }
            }

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

                ForEach(UIElementCommand.Predicate.Properties.allCases) { property in
                  HStack {
                    Toggle(isOn: Binding<Bool>(
                      get: { predicates[index].properties.contains(property) },
                      set: {
                        if $0 {
                          predicates[index].properties.append(property)
                        } else {
                          predicates[index].properties.removeAll(where: { $0 == property })
                        }
                        validation = updateAndValidatePayload()
                      }
                    ), label: {
                      Text(property.displayName)
                    })
                  }
                }
              }
            }
          }
          .roundedSubStyle(padding: 8)
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
        }
        .roundedSubStyle(padding: 8)
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
    .enableInjection()
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
        Text(captureStore.isCapturing ? "Stop Capture" : "Capture UI Element")
      }
    })
    .environment(\.buttonCalm, false)
    .environment(\.buttonFocusEffect, true)
    .environment(\.buttonHoverEffect, false)
    .environment(\.buttonBackgroundColor, .systemGreen)
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

import SwiftUI

struct TextCommandView: View {
  let kind: CommandViewModel.Kind.TextModel.Kind
  let metaData: CommandViewModel.MetaData
  let onSetFindTo: (SetFindToView.Action) -> Void
  let onTypeAction: (TypeCommandView.Action) -> Void

  var body: some View {
    switch kind {
    case .setFindTo(let model):
      SetFindToView(metaData, model: model, onAction: onSetFindTo)
    case .type(let model):
      TypeCommandView(metaData, model: model, onAction: onTypeAction)
    }
  }
}

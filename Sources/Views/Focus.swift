enum Focus: Hashable {
  case sidebar
  case main(MainComponent)
  case detail(DetailComponent)

  enum MainComponent: Hashable {
    case groupComponent
  }

  enum DetailComponent: Hashable {
    case info(Workflow)
    case shortcuts(Workflow)
    case commands(Workflow)
  }
}

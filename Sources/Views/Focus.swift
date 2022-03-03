enum Focus: Hashable {
  case sidebar(SidebarComponent)
  case main(MainComponent)
  case detail(DetailComponent)

  enum SidebarComponent {
    case list
    case configuration
  }

  enum MainComponent: Hashable {
    case groupComponent
  }

  enum DetailComponent: Hashable {
    case info(Workflow)
    case shortcuts(Workflow)
    case commands(Workflow)
  }
}

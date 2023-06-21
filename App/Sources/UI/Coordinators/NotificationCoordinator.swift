import Combine
import Foundation

final class NotificationCoordinator {
  private let mapper: DetailModelMapper
  private var subscription: AnyCancellable?

  @MainActor
  let publisher = ViewModelsPublisher<NotificationViewModel>()

  init(_ applicationStore: ApplicationStore) {
    self.mapper = DetailModelMapper(applicationStore)
  }

  func subscribe(to publisher: Published<Command?>.Publisher) {
    subscription = publisher
      .compactMap { $0 }
      .filter(\.notification)
      .sink { [weak self] value in
        self?.process(value)
      }
  }

  // MARK: - Private methods

  private func process(_ command: Command) {
    Task {
      let commandViewModel: CommandViewModel = mapper.map(command)
      let viewModel = NotificationViewModel(id: commandViewModel.meta.id,
                                            icon: commandViewModel.meta.icon,
                                            name: commandViewModel.meta.name,
                                            result: .success)
      await publisher.publish([viewModel])
    }
  }
}

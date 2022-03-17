import Core
import Combine
import SwiftUI

@MainActor
class InfoViewModel: ObservableObject {
    var backup: ArchiveItem
    @Published var item: ArchiveItem
    @Published var isEditMode = false
    @Published var isError = false
    var error = ""

    let appState: AppState = .shared
    var dismissPublisher = PassthroughSubject<Void, Never>()
    var disposeBag = DisposeBag()

    init(item: ArchiveItem?) {
        self.item = item ?? .none
        self.backup = item ?? .none
        watchIsFavorite()
    }

    func watchIsFavorite() {
        $item
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                guard !self.isEditMode else { return }
                guard self.backup.isFavorite != self.item.isFavorite else {
                    return
                }
                self.saveChanges()
            }
            .store(in: &disposeBag)
    }

    func edit() {
        withAnimation {
            isEditMode = true
        }
    }

    func share() {
        Core.share(item)
    }

    func delete() {
        Task {
            try await appState.archive.delete(item.id)
            await appState.synchronize()
        }
        dismiss()
    }

    func saveChanges() {
        guard item != backup else {
            withAnimation {
                isEditMode = false
            }
            return
        }
        Task {
            do {
                if backup.name != item.name {
                    try await appState.archive.rename(backup.id, to: item.name)
                }
                try await appState.archive.upsert(item)
                backup = item
                withAnimation {
                    isEditMode = false
                    item.status = .synchronizing
                }
                await appState.synchronize()
                withAnimation {
                    item.status = .synchronized
                }
            } catch {
                item.status = .error
                showError(error)
            }
        }
    }

    func undoChanges() {
        item = backup
        withAnimation {
            isEditMode = false
        }
    }

    func showError(_ error: Swift.Error) {
        self.error = String(describing: error)
        self.isError = true
    }

    func dismiss() {
        dismissPublisher.send(())
    }
}

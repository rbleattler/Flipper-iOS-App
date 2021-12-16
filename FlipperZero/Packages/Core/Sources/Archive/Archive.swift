import Combine
import Inject
import Foundation

public class Archive: ObservableObject {
    public static let shared: Archive = .init()

    @Inject var storage: ArchiveStorage
    @Inject var synchronization: SynchronizationProtocol

    var start: Date = .init()
    @Published public var isSynchronizing = false {
        didSet {
            switch isSynchronizing {
            case true: start = .init()
            case false: print(Date().timeIntervalSince(start))
            }
        }
    }

    @Published public var items: [ArchiveItem] = [] {
        didSet {
            storage.items = items
        }
    }

    private init() {
        items = storage.items
    }

    func getManifest() -> Manifest {
        var items = [Manifest.Item]()
        for item in self.items.filter({ $0.status != .deleted }) {
            items.append(.init(path: item.path, hash: item.hash))
        }
        return .init(items: items)
    }

    public func replace(_ item: ArchiveItem) {
        items.removeAll { $0.id == item.id }
        items.append(item)
    }

    public func delete(_ item: ArchiveItem) {
        updateStatus(of: item, to: .deleted)
    }

    func delete(at path: Path) {
        if let item = items.first(where: { $0.path == path }) {
            updateStatus(of: item, to: .deleted)
        }
    }

    public func wipe(_ item: ArchiveItem) {
        items.removeAll { $0.id == item.id }
    }

    public func restore(_ item: ArchiveItem) {
        let manifest = getManifest()
        if let exising = manifest[item.path], exising.hash == item.hash {
            updateStatus(of: item, to: .synchronizied)
        } else {
            updateStatus(of: item, to: .imported)
        }
    }

    public func favorite(_ item: ArchiveItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            objectWillChange.send()
            items[index].isFavorite.toggle()
        }
    }

    func updateStatus(
        of item: ArchiveItem,
        to status: ArchiveItem.Status
    ) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            objectWillChange.send()
            items[index].status = status
        }
    }

    public func importKey(_ item: ArchiveItem) {
        if !items.contains(where: {
            item.id == $0.id && item.content == $0.content
        }) {
            var item = item
            item.status = .imported
            replace(item)
        }
    }

    public func syncWithDevice() async {
        guard !isSynchronizing else { return }
        isSynchronizing = true
        defer { isSynchronizing = false }

        do {
            try await synchronization.syncWithDevice()
        } catch {
            print("syncronization error", error)
        }
    }
}

extension ArchiveItem {
    var path: Path {
        .init(components: ["ext", fileType.directory, fileName])
    }
}

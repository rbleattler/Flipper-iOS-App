import Peripheral
import Foundation
import OrderedCollections

class PlainLoggerStorage: LoggerStorage {
    let storage: FileStorage = .init()
    private let directory = Path("logs")

    private  var logs: OrderedDictionary<String, [String]> = [:]

    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss dd-MM-yyyy"
        return formatter
    }()

    private var current: String

    init() {
        current = formatter.string(from: Date())
    }

    func list() -> [String] {
        let files = (try? storage.list(at: directory)) ?? []
        return files.sorted {
            guard let first = formatter.date(from: $0) else { return false }
            guard let second = formatter.date(from: $1) else { return false }
            return first < second
        }
    }

    func read(_ name: String) -> [String] {
        guard let log = try? storage.read(directory.appending(name)) else {
            return []
        }
        return log.split(separator: "\n").map { String($0) }
    }

    func write(_ message: String) {
        try? storage.append("\(message)\n", at: directory.appending(current))
    }

    func delete(_ name: String) {
        try? storage.delete(directory.appending(name))
    }
}

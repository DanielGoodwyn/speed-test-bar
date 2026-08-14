import Foundation
import Combine

class HistoryStore: ObservableObject {
    @Published var results: [SpeedTestResult] = []

    private let fileURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("SpeedTest", isDirectory: true)

        // Create directory if needed
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)

        self.fileURL = appDir.appendingPathComponent("history.json")
        self.results = Self.load(from: fileURL)
    }

    private static func load(from url: URL) -> [SpeedTestResult] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([SpeedTestResult].self, from: data)) ?? []
    }

    func add(_ result: SpeedTestResult) {
        results.insert(result, at: 0)
        save()
    }

    func clear() {
        results.removeAll()
        save()
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(results) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    func exportCSV() -> String {
        var csv = "Timestamp,Download (Mbps),Upload (Mbps),Ping (ms),Latitude,Longitude\n"
        let formatter = ISO8601DateFormatter()
        for r in results {
            let lat = r.latitude.map { String(format: "%.6f", $0) } ?? ""
            let lng = r.longitude.map { String(format: "%.6f", $0) } ?? ""
            csv += "\(formatter.string(from: r.timestamp)),\(String(format: "%.2f", r.downloadMbps)),\(String(format: "%.2f", r.uploadMbps)),\(String(format: "%.1f", r.pingMs)),\(lat),\(lng)\n"
        }
        return csv
    }
}

import Foundation

struct SpeedTestResult: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let downloadMbps: Double
    let uploadMbps: Double
    let pingMs: Double
    let latitude: Double?
    let longitude: Double?

    init(
        downloadMbps: Double,
        uploadMbps: Double,
        pingMs: Double,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.downloadMbps = downloadMbps
        self.uploadMbps = uploadMbps
        self.pingMs = pingMs
        self.latitude = latitude
        self.longitude = longitude
    }
}

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

enum MonitoringMode: Int, CaseIterable {
    case intense = 120 // 2 minutes
    case high = 300 // 5 minutes
    case normal = 3600 // 1 hour
    case low = 7200 // 2 hours
    case lowest = 43200 // 12 hours
    
    var displayName: String {
        switch self {
        case .intense: return "Intense (2m)"
        case .high: return "High (5m)"
        case .normal: return "Normal (1h)"
        case .low: return "Low (2h)"
        case .lowest: return "Lowest (12h)"
        }
    }
    
    var testDuration: Int {
        switch self {
        case .intense: return 3
        case .high: return 5
        case .normal: return 8
        case .low: return 10
        case .lowest: return 15
        }
    }
}

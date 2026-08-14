import SwiftUI
import MapKit

// MARK: - Grid Cell Model

struct GridCell: Identifiable {
    let id = UUID()
    let latIndex: Int
    let lngIndex: Int
    let centerLat: Double
    let centerLng: Double
    let avgDownloadMbps: Double
    let avgUploadMbps: Double
    let avgPingMs: Double
    let testCount: Int

    var region: MKCoordinateRegion {
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng),
            latitudinalMeters: GridCell.cellSizeMeters,
            longitudinalMeters: GridCell.cellSizeMeters
        )
    }

    // ~400m per side (half quarter mile)
    static let cellSizeMeters: Double = 400.0
    // In degrees: ~0.0036° lat, ~0.0045° lng at mid-latitudes
    static let cellSizeLat: Double = 0.0036
    static let cellSizeLng: Double = 0.0045

    static func gridIndex(lat: Double, lng: Double) -> (Int, Int) {
        let latIdx = Int(floor(lat / cellSizeLat))
        let lngIdx = Int(floor(lng / cellSizeLng))
        return (latIdx, lngIdx)
    }

    static func cellCenter(latIndex: Int, lngIndex: Int) -> (Double, Double) {
        let lat = (Double(latIndex) + 0.5) * cellSizeLat
        let lng = (Double(lngIndex) + 0.5) * cellSizeLng
        return (lat, lng)
    }
}

// MARK: - Heat Map View

struct HeatMapView: View {
    @ObservedObject var store: HistoryStore
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedCell: GridCell?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerBar

            if gridCells.isEmpty {
                emptyState
            } else {
                ZStack(alignment: .bottomTrailing) {
                    mapContent
                    legendOverlay
                }
            }
        }
        .frame(minWidth: 700, minHeight: 500)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Image(systemName: "map.fill")
                .font(.title2)
                .foregroundStyle(.tint)

            Text("Speed Heat Map")
                .font(.title2.bold())

            Spacer()

            if !gridCells.isEmpty {
                HStack(spacing: 12) {
                    Text("\(gridCells.count) zone\(gridCells.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    let totalTests = gridCells.reduce(0) { $0 + $1.testCount }
                    Text("\(totalTests) test\(totalTests == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
    }

    // MARK: - Map

    private var mapContent: some View {
        Map(position: $position) {
            ForEach(gridCells) { cell in
                MapPolygon(coordinates: cellCorners(cell))
                    .foregroundStyle(speedColor(cell.avgDownloadMbps).opacity(0.45))
                    .stroke(speedColor(cell.avgDownloadMbps), lineWidth: 1.5)

                // Center annotation with speed label
                Annotation("", coordinate: CLLocationCoordinate2D(latitude: cell.centerLat, longitude: cell.centerLng)) {
                    VStack(spacing: 1) {
                        Text(String(format: "%.0f", cell.avgDownloadMbps))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Mbps")
                            .font(.system(size: 8, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                        Text("\(cell.testCount) test\(cell.testCount == 1 ? "" : "s")")
                            .font(.system(size: 7, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(speedColor(cell.avgDownloadMbps).opacity(0.85))
                    .cornerRadius(6)
                    .shadow(color: .black.opacity(0.3), radius: 3, y: 1)
                    .onTapGesture {
                        selectedCell = cell
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .flat))
        .overlay(alignment: .top) {
            if let cell = selectedCell {
                cellDetailCard(cell)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - Cell Detail Card

    private func cellDetailCard(_ cell: GridCell) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Zone Details")
                    .font(.headline)
                Text(String(format: "📍 %.4f, %.4f", cell.centerLat, cell.centerLng))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            Divider().frame(height: 40)

            VStack(spacing: 2) {
                Text(String(format: "↓ %.1f", cell.avgDownloadMbps))
                    .font(.system(.body, design: .rounded).bold())
                    .foregroundColor(speedColor(cell.avgDownloadMbps))
                Text("Mbps")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 2) {
                Text(String(format: "↑ %.1f", cell.avgUploadMbps))
                    .font(.system(.body, design: .rounded).bold())
                    .foregroundColor(.blue)
                Text("Mbps")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 2) {
                Text(String(format: "%.0f", cell.avgPingMs))
                    .font(.system(.body, design: .rounded).bold())
                    .foregroundColor(.orange)
                Text("ms")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 2) {
                Text("\(cell.testCount)")
                    .font(.system(.body, design: .rounded).bold())
                Text("tests")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                withAnimation { selectedCell = nil }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.2), radius: 8, y: 2)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Legend

    private var legendOverlay: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Download Speed")
                .font(.caption2.bold())
                .foregroundColor(.secondary)

            HStack(spacing: 3) {
                legendSwatch(color: .red, label: "<25")
                legendSwatch(color: .orange, label: "25-50")
                legendSwatch(color: .yellow, label: "50-100")
                legendSwatch(color: .green, label: "100+")
            }

            Text("Mbps")
                .font(.system(size: 8))
                .foregroundColor(.secondary)
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
        .padding(12)
    }

    private func legendSwatch(color: Color, label: String) -> some View {
        VStack(spacing: 2) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color.opacity(0.6))
                .frame(width: 24, height: 12)
            Text(label)
                .font(.system(size: 7))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "map")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No location data yet")
                .font(.title3)
                .foregroundColor(.secondary)
            Text("Speed tests need location permission to appear on the heat map")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Grid Computation

    private var gridCells: [GridCell] {
        // Filter to results that have location data
        let located = store.results.filter { $0.latitude != nil && $0.longitude != nil }
        guard !located.isEmpty else { return [] }

        // Group by grid cell
        var groups: [String: [SpeedTestResult]] = [:]
        for result in located {
            let (latIdx, lngIdx) = GridCell.gridIndex(lat: result.latitude!, lng: result.longitude!)
            let key = "\(latIdx),\(lngIdx)"
            groups[key, default: []].append(result)
        }

        // Build grid cells with averages
        return groups.map { (key, results) in
            let parts = key.split(separator: ",")
            let latIdx = Int(parts[0])!
            let lngIdx = Int(parts[1])!
            let (centerLat, centerLng) = GridCell.cellCenter(latIndex: latIdx, lngIndex: lngIdx)

            let avgDown = results.reduce(0.0) { $0 + $1.downloadMbps } / Double(results.count)
            let avgUp = results.reduce(0.0) { $0 + $1.uploadMbps } / Double(results.count)
            let avgPing = results.reduce(0.0) { $0 + $1.pingMs } / Double(results.count)

            return GridCell(
                latIndex: latIdx,
                lngIndex: lngIdx,
                centerLat: centerLat,
                centerLng: centerLng,
                avgDownloadMbps: avgDown,
                avgUploadMbps: avgUp,
                avgPingMs: avgPing,
                testCount: results.count
            )
        }
    }

    // MARK: - Helpers

    private func cellCorners(_ cell: GridCell) -> [CLLocationCoordinate2D] {
        let halfLat = GridCell.cellSizeLat / 2.0
        let halfLng = GridCell.cellSizeLng / 2.0
        let lat = cell.centerLat
        let lng = cell.centerLng

        return [
            CLLocationCoordinate2D(latitude: lat - halfLat, longitude: lng - halfLng),
            CLLocationCoordinate2D(latitude: lat - halfLat, longitude: lng + halfLng),
            CLLocationCoordinate2D(latitude: lat + halfLat, longitude: lng + halfLng),
            CLLocationCoordinate2D(latitude: lat + halfLat, longitude: lng - halfLng),
        ]
    }

    private func speedColor(_ mbps: Double) -> Color {
        switch mbps {
        case 100...: return .green
        case 50..<100: return .yellow
        case 25..<50: return .orange
        default: return .red
        }
    }
}

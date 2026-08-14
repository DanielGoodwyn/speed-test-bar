import SwiftUI
import Charts

struct ChartView: View {
    @ObservedObject var store: HistoryStore
    @ObservedObject var filterState: FilterState
    @State private var selectedDate: Date?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerBar
            
            if filteredResults.isEmpty {
                emptyState
            } else {
                chartContent
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    // MARK: - Header
    
    private var headerBar: some View {
        HStack {
            Image(systemName: "chart.xyaxis.line")
                .font(.title2)
                .foregroundStyle(.tint)
            
            Text("Speed History Chart")
                .font(.title2.bold())
            
            Spacer()
            
            if !filteredResults.isEmpty {
                let maxDown = filteredResults.map { $0.downloadMbps }.max() ?? 0
                let maxUp = filteredResults.map { $0.uploadMbps }.max() ?? 0
                
                HStack(spacing: 12) {
                    Text(String(format: "Max Down: %.1f Mbps", maxDown))
                        .font(.caption)
                        .foregroundColor(speedColor(maxDown))
                    
                    Text(String(format: "Max Up: %.1f Mbps", maxUp))
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Chart Content
    
    private var chartContent: some View {
        Chart {
            ForEach(filteredResults) { result in
                // Download Line
                LineMark(
                    x: .value("Time", result.timestamp),
                    y: .value("Download", result.downloadMbps),
                    series: .value("Type", "Download")
                )
                .foregroundStyle(Color.green)
                .interpolationMethod(.catmullRom)
                
                AreaMark(
                    x: .value("Time", result.timestamp),
                    y: .value("Download", result.downloadMbps),
                    series: .value("Type", "Download")
                )
                .foregroundStyle(
                    Gradient(colors: [Color.green.opacity(0.3), Color.green.opacity(0.0)])
                )
                .interpolationMethod(.catmullRom)
                
                // Upload Line
                LineMark(
                    x: .value("Time", result.timestamp),
                    y: .value("Upload", result.uploadMbps),
                    series: .value("Type", "Upload")
                )
                .foregroundStyle(Color.blue)
                .interpolationMethod(.catmullRom)
                
                AreaMark(
                    x: .value("Time", result.timestamp),
                    y: .value("Upload", result.uploadMbps),
                    series: .value("Type", "Upload")
                )
                .foregroundStyle(
                    Gradient(colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.0)])
                )
                .interpolationMethod(.catmullRom)
            }
            
            if let selected = selectedResult {
                RuleMark(
                    x: .value("Selected", selected.timestamp)
                )
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                .foregroundStyle(Color.secondary)
                
                PointMark(
                    x: .value("Time", selected.timestamp),
                    y: .value("Download", selected.downloadMbps)
                )
                .foregroundStyle(Color.green)
                .annotation(position: .topTrailing, spacing: 10, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selected.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(String(format: "↓ %.1f Mbps", selected.downloadMbps))
                            .font(.caption.bold())
                            .foregroundColor(speedColor(selected.downloadMbps))
                        Text(String(format: "↑ %.1f Mbps", selected.uploadMbps))
                            .font(.caption.bold())
                            .foregroundColor(.blue)
                        Text(String(format: "⚡ %.0f ms", selected.pingMs))
                            .font(.caption.bold())
                            .foregroundColor(.orange)
                    }
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                }
                
                PointMark(
                    x: .value("Time", selected.timestamp),
                    y: .value("Upload", selected.uploadMbps)
                )
                .foregroundStyle(Color.blue)
            }
        }
        .chartXSelection(value: $selectedDate)
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day().hour().minute())
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisTick()
                if let v = value.as(Double.self) {
                    AxisValueLabel("\(Int(v)) Mbps")
                }
            }
        }
        .padding(20)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No data to chart")
                .font(.title3)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Computed Properties
    
    private var filteredResults: [SpeedTestResult] {
        store.results.filter { result in
            // Filter by Hour Blocks
            if !filterState.selectedHourBlocks.isEmpty {
                let hour = Calendar.current.component(.hour, from: result.timestamp)
                if !filterState.selectedHourBlocks.contains(hour) { return false }
            }
            
            // Filter by Map Cell
            if let cell = filterState.selectedGridCell {
                guard let lat = result.latitude, let lng = result.longitude else { return false }
                let (latIdx, lngIdx) = GridCell.gridIndex(lat: lat, lng: lng)
                if latIdx != cell.latIndex || lngIdx != cell.lngIndex { return false }
            }
            
            // Filter by Selected Records (if any are selected in the list)
            if !filterState.selectedRecordIDs.isEmpty {
                if !filterState.selectedRecordIDs.contains(result.id) { return false }
            }
            
            return true
        }
        .sorted(by: { $0.timestamp < $1.timestamp }) // Charts need chronological data
    }
    
    private var selectedResult: SpeedTestResult? {
        guard let date = selectedDate else { return nil }
        return filteredResults.min(by: { abs($0.timestamp.timeIntervalSince(date)) < abs($1.timestamp.timeIntervalSince(date)) })
    }
    
    // MARK: - Helpers
    
    private func speedColor(_ mbps: Double) -> Color {
        switch mbps {
        case 100...: return .green
        case 50..<100: return .yellow
        case 25..<50: return .orange
        default: return .red
        }
    }
}

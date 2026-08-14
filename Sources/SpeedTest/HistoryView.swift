import SwiftUI

struct HistoryView: View {
    @ObservedObject var store: HistoryStore
    @ObservedObject var filterState: FilterState
    @State private var sortOrder = [KeyPathComparator(\SpeedTestResult.timestamp, order: .reverse)]
    @State private var showExportAlert = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerBar

            // Table
            if store.results.isEmpty {
                emptyState
            } else {
                resultTable
            }

            // Footer
            footerBar
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Image(systemName: "speedometer")
                .font(.title2)
                .foregroundStyle(.tint)

            Text("Speed Test History")
                .font(.title2.bold())

            Spacer()

            if let latest = store.results.first {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 16) {
                        statBadge(icon: "arrow.down.circle.fill", value: String(format: "%.1f", latest.downloadMbps), unit: "Mbps", color: speedColor(latest.downloadMbps))
                        statBadge(icon: "arrow.up.circle.fill", value: String(format: "%.1f", latest.uploadMbps), unit: "Mbps", color: .blue)
                        statBadge(icon: "bolt.circle.fill", value: String(format: "%.0f", latest.pingMs), unit: "ms", color: .orange)
                    }
                    VStack(alignment: .trailing, spacing: 8) {
                        statBadge(icon: "arrow.down.circle.fill", value: String(format: "%.1f", latest.downloadMbps), unit: "Mbps", color: speedColor(latest.downloadMbps))
                        statBadge(icon: "arrow.up.circle.fill", value: String(format: "%.1f", latest.uploadMbps), unit: "Mbps", color: .blue)
                        statBadge(icon: "bolt.circle.fill", value: String(format: "%.0f", latest.pingMs), unit: "ms", color: .orange)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
    }

    private func statBadge(icon: String, value: String, unit: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(value)
                .font(.system(.body, design: .rounded).bold())
                .lineLimit(1)
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .fixedSize(horizontal: true, vertical: false)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: - Table

    private var resultTable: some View {
        Table(sortedResults, selection: $filterState.selectedRecordIDs, sortOrder: $sortOrder) {
            TableColumn("Date & Time", sortUsing: KeyPathComparator(\SpeedTestResult.timestamp, order: .reverse)) { result in
                Text(result.timestamp, format: .dateTime.month(.abbreviated).day().hour().minute())
                    .font(.system(.body, design: .monospaced))
            }
            .width(min: 140, ideal: 170)

            TableColumn("Download", sortUsing: KeyPathComparator(\SpeedTestResult.downloadMbps, order: .reverse)) { result in
                HStack {
                    Circle()
                        .fill(speedColor(result.downloadMbps))
                        .frame(width: 8, height: 8)
                    Text(String(format: "%.1f Mbps", result.downloadMbps))
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(speedColor(result.downloadMbps))
                }
            }
            .width(min: 100, ideal: 130)

            TableColumn("Upload", sortUsing: KeyPathComparator(\SpeedTestResult.uploadMbps, order: .reverse)) { result in
                Text(String(format: "%.1f Mbps", result.uploadMbps))
                    .font(.system(.body, design: .rounded))
            }
            .width(min: 90, ideal: 110)

            TableColumn("Ping", sortUsing: KeyPathComparator(\SpeedTestResult.pingMs)) { result in
                Text(String(format: "%.0f ms", result.pingMs))
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(pingColor(result.pingMs))
            }
            .width(min: 60, ideal: 80)

            TableColumn("Latitude") { result in
                Text(result.latitude.map { String(format: "%.4f", $0) } ?? "—")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(result.latitude != nil ? .primary : .secondary)
            }
            .width(min: 80, ideal: 100)

            TableColumn("Longitude") { result in
                Text(result.longitude.map { String(format: "%.4f", $0) } ?? "—")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(result.longitude != nil ? .primary : .secondary)
            }
            .width(min: 80, ideal: 100)
        }
    }

    private var sortedResults: [SpeedTestResult] {
        store.results.filter { result in
            // Filter by Hour Blocks (if any are selected)
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
            
            return true
        }.sorted(using: sortOrder)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "wifi.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No speed tests yet")
                .font(.title3)
                .foregroundColor(.secondary)
            Text("Click the menu bar icon or wait for the next automatic test")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Footer

    private var footerBar: some View {
        HStack {
            Text("\(store.results.count) test\(store.results.count == 1 ? "" : "s") recorded")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Button {
                exportCSV()
            } label: {
                Label("Export CSV", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.borderless)

            Button(role: .destructive) {
                store.clear()
            } label: {
                Label("Clear All", systemImage: "trash")
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
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

    private func pingColor(_ ms: Double) -> Color {
        switch ms {
        case ..<20: return .green
        case 20..<50: return .yellow
        case 50..<100: return .orange
        default: return .red
        }
    }

    private func exportCSV() {
        let csv = store.exportCSV()
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = "speed_test_history.csv"

        if panel.runModal() == .OK, let url = panel.url {
            try? csv.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}

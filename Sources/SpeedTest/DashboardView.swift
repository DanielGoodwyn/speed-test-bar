import SwiftUI

struct DashboardView: View {
    enum DetailMode: String, CaseIterable {
        case map = "Map"
        case chart = "Chart"
    }

    @ObservedObject var store: HistoryStore
    var runTestAction: (() -> Void)? = nil
    var modeChangeAction: ((MonitoringMode) -> Void)? = nil
    
    @StateObject private var filterState = FilterState()
    @State private var detailMode: DetailMode = .map
    @AppStorage("MonitoringMode") private var rawMonitoringMode: Int = MonitoringMode.high.rawValue
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Filter Bar
            HStack {
                Picker("", selection: $detailMode) {
                    ForEach(DetailMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
                
                Divider().frame(height: 20).padding(.horizontal, 8)
                
                Text("Hour of Day:")
                    .font(.headline)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(0..<24, id: \.self) { hour in
                            let isSelected = filterState.selectedHourBlocks.contains(hour)
                            Button {
                                withAnimation {
                                    if isSelected {
                                        filterState.selectedHourBlocks.remove(hour)
                                    } else {
                                        filterState.selectedHourBlocks.insert(hour)
                                    }
                                }
                            } label: {
                                Text(formatHour(hour))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(isSelected ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                                    .foregroundColor(isSelected ? .white : .primary)
                                    .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Spacer()
                
                if !filterState.selectedHourBlocks.isEmpty || filterState.selectedGridCell != nil || !filterState.selectedRecordIDs.isEmpty {
                    Button("Clear Filters") {
                        withAnimation {
                            filterState.selectedHourBlocks.removeAll()
                            filterState.selectedGridCell = nil
                            filterState.selectedRecordIDs.removeAll()
                        }
                    }
                    .buttonStyle(.link)
                    .padding(.trailing, 8)
                }
                
                Divider().frame(height: 20).padding(.horizontal, 4)
                
                Picker("", selection: $rawMonitoringMode) {
                    ForEach(MonitoringMode.allCases, id: \.rawValue) { mode in
                        Text(mode.displayName).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 140)
                .onChange(of: rawMonitoringMode) { old, new in
                    if let mode = MonitoringMode(rawValue: new) {
                        modeChangeAction?(mode)
                    }
                }
                
                if let runTest = runTestAction {
                    Button {
                        runTest()
                    } label: {
                        Label("Run Speed Test", systemImage: "play.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            
            Divider()
            
            // Split View for History and Map/Chart
            NavigationSplitView {
                HistoryView(store: store, filterState: filterState)
                    .navigationSplitViewColumnWidth(min: 250, ideal: 450)
            } detail: {
                if detailMode == .map {
                    HeatMapView(store: store, filterState: filterState)
                } else {
                    ChartView(store: store, filterState: filterState)
                }
            }
        }
    }
    
    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        
        var comps = DateComponents()
        comps.hour = hour
        let d = Calendar.current.date(from: comps) ?? Date()
        return formatter.string(from: d)
    }
}

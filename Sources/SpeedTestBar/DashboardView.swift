import SwiftUI

struct DashboardView: View {
    @ObservedObject var store: HistoryStore
    @StateObject private var filterState = FilterState()
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Filter Bar
            HStack {
                Text("Hour of Day:")
                    .font(.headline)
                
                Picker("", selection: $filterState.selectedHourBlock) {
                    Text("All Times").tag(Int?.none)
                    ForEach(0..<24, id: \.self) { hour in
                        Text(formatHour(hour)).tag(Int?.some(hour))
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 150)
                
                Spacer()
                
                if filterState.selectedHourBlock != nil || filterState.selectedGridCell != nil || !filterState.selectedRecordIDs.isEmpty {
                    Button("Clear Filters") {
                        withAnimation {
                            filterState.selectedHourBlock = nil
                            filterState.selectedGridCell = nil
                            filterState.selectedRecordIDs.removeAll()
                        }
                    }
                    .buttonStyle(.link)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            
            Divider()
            
            // Split View for History and Map
            NavigationSplitView {
                HistoryView(store: store, filterState: filterState)
                    .navigationSplitViewColumnWidth(min: 400, ideal: 550)
            } detail: {
                HeatMapView(store: store, filterState: filterState)
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

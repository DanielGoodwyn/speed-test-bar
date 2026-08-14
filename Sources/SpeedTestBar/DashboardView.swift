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
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            
            Divider()
            
            // Split View for History and Map
            NavigationSplitView {
                HistoryView(store: store, filterState: filterState)
                    .navigationSplitViewColumnWidth(min: 250, ideal: 450)
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

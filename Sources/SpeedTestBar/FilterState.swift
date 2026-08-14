import SwiftUI
import Combine

class FilterState: ObservableObject {
    @Published var selectedGridCell: GridCell?
    @Published var selectedRecordIDs: Set<UUID> = []
    @Published var selectedHourBlock: Int? // 0-23
}

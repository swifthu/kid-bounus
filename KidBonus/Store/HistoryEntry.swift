import Foundation
import SwiftData

/// 与 SwiftData 解耦的轻量记录视图模型。
/// 分组、去重、计数等逻辑只需要这些字段，用值类型承载后可在无 container 的环境下纯单元测试。
struct HistoryEntry: Equatable, Identifiable {
    let id: UUID
    let title: String
    let delta: Int
    let timestamp: Date
    let kidID: UUID?
    let sourceKind: SourceKind
}

extension HistoryRecord {
    var entry: HistoryEntry {
        HistoryEntry(
            id: id,
            title: title,
            delta: delta,
            timestamp: timestamp,
            kidID: kid?.id,
            sourceKind: sourceKind
        )
    }
}

extension Array where Element == HistoryRecord {
    var entries: [HistoryEntry] { map(\.entry) }
}

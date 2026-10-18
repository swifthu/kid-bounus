import Foundation

struct HistoryDayGroup: Equatable, Identifiable {
    let key: String
    let entries: [HistoryEntry]
    var id: String { key }
}

/// 「历程」页的按天分组与标签逻辑。
enum HistoryGrouping {
    /// 按天分组。天按时间**降序**（最近的一天排在最前），组内记录同样按时间倒序。
    /// 依赖 DateKey 的零填充格式：`yyyy-MM-dd` 的字典序与时间序一致。
    static func group(_ entries: [HistoryEntry]) -> [HistoryDayGroup] {
        Dictionary(grouping: entries) { DateKey.day($0.timestamp) }
            .map { HistoryDayGroup(key: $0.key, entries: $0.value.sorted { $0.timestamp > $1.timestamp }) }
            .sorted { $0.key > $1.key }
    }

    /// 天标签：今天 / 昨天 / M月d日。无法解析时原样返回。
    static func label(for key: String) -> String {
        if key == DateKey.today { return "今天" }
        if key == DateKey.day(before: 1) { return "昨天" }
        let parts = key.split(separator: "-").compactMap { Int($0) }
        if parts.count == 3 { return "\(parts[1])月\(parts[2])日" }
        return key
    }

    /// kidID 为 nil 表示「全部」。
    static func filter(_ entries: [HistoryEntry], kidID: UUID?) -> [HistoryEntry] {
        guard let kidID else { return entries }
        return entries.filter { $0.kidID == kidID }
    }

    static func timeText(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
}

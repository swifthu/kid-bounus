import Foundation

/// 历程页的日期区间筛选：选定某一天（anchor）后，向前取一个窗口。
enum HistoryDateRange: String, CaseIterable, Identifiable {
    case day, week, month

    var id: String { rawValue }

    var label: String {
        switch self {
        case .day:   return "当天"
        case .week:  return "近7天"
        case .month: return "近30天"
        }
    }

    /// 窗口天数（含 anchor 当天）
    var days: Int {
        switch self {
        case .day:   return 1
        case .week:  return 7
        case .month: return 30
        }
    }

    /// 窗口起止日。日期键是 yyyy-MM-dd，字典序即时序，可以直接比字符串。
    func window(anchor: Date) -> (start: String, end: String) {
        let cal = Calendar.current
        let day = cal.startOfDay(for: anchor)
        let start = cal.date(byAdding: .day, value: -(days - 1), to: day) ?? day
        return (DateKey.day(start), DateKey.day(day))
    }

    func contains(_ date: Date, anchor: Date) -> Bool {
        let w = window(anchor: anchor)
        let key = DateKey.day(date)
        return key >= w.start && key <= w.end
    }
}

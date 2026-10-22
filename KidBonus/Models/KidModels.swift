import Foundation
import SwiftData

enum Kind: String, Codable, CaseIterable, Identifiable {
    case add, deduct
    var id: String { rawValue }
}

enum ProductCategory: String, Codable, CaseIterable, Identifiable {
    case toy, book, food, priv, out
    var id: String { rawValue }
    var label: String {
        switch self {
        case .toy:  return "玩具"
        case .book: return "图书"
        case .food: return "零食"
        case .priv: return "特权"
        case .out:  return "外出"
        }
    }
}

enum SourceKind: String, Codable {
    case preset, freeform, streakBonus, redemption, adjust
}

enum DateKey {
    static func day(_ date: Date) -> String {
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        let y = comps.year ?? 0
        let m = String(format: "%02d", comps.month ?? 1)
        let d = String(format: "%02d", comps.day ?? 1)
        return "\(y)-\(m)-\(d)"
    }
    static var today: String { day(.now) }
    static func day(before days: Int) -> String {
        let d = Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
        return day(d)
    }

    /// "yyyy-MM-dd" 的前一天，用来数连续天数。跨月跨年也对。
    static func previousDay(of key: String) -> String? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        var comps = DateComponents()
        comps.year = parts[0]
        comps.month = parts[1]
        comps.day = parts[2]
        guard let date = Calendar.current.date(from: comps),
              let prev = Calendar.current.date(byAdding: .day, value: -1, to: date) else { return nil }
        return day(prev)
    }
}

@Model
final class Streak {
    var kidID: UUID
    /// 属于哪个加分项。连续天数按「孩子 + 项目」分别统计：
    /// 「每天读 30 分钟」和「每天练琴」是两回事，混在一起算没有意义。
    /// nil 是旧数据里不分项目的连续天数，已经不再使用。
    var itemID: UUID?
    var count: Int
    var lastDateKey: String?

    init(kidID: UUID, itemID: UUID? = nil, count: Int = 0, lastDateKey: String? = nil) {
        self.kidID = kidID
        self.itemID = itemID
        self.count = count
        self.lastDateKey = lastDateKey
    }
}

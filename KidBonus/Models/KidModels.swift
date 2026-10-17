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
    case preset, freeform, streakBonus, redemption
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
}

@Model
final class Streak {
    var kidID: UUID
    var count: Int
    var lastDateKey: String?

    init(kidID: UUID, count: Int = 0, lastDateKey: String? = nil) {
        self.kidID = kidID
        self.count = count
        self.lastDateKey = lastDateKey
    }
}

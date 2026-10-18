import Foundation

struct FreeformChip: Equatable, Identifiable {
    let title: String
    let delta: Int
    var id: String { title + "||" + String(delta) }
}

/// 「最近自定义记录」快捷标签。
enum FreeformRecents {
    /// 只取 `sourceKind == .freeform`，按 `title+delta` 去重，保持传入顺序（调用方按时间倒序传入）。
    /// 结果稳定：同一输入永远得到同一输出，不依赖 Dictionary 迭代顺序。
    static func chips(from entries: [HistoryEntry], limit: Int = 5) -> [FreeformChip] {
        var seen = Set<String>()
        var out: [FreeformChip] = []
        for entry in entries where entry.sourceKind == .freeform {
            let chip = FreeformChip(title: entry.title, delta: entry.delta)
            guard seen.insert(chip.id).inserted else { continue }
            out.append(chip)
            if out.count == limit { break }
        }
        return out
    }
}

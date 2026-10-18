import Foundation

/// 当前孩子的解析。集中在一处，避免各视图重复写法，也避免空列表时 `kids[0]` 越界。
enum KidPicker {
    /// storedID 有效且在可用列表中则返回它，否则回退到首个；列表为空返回 nil。
    static func resolve(storedID: String, availableIDs: [UUID]) -> UUID? {
        guard !availableIDs.isEmpty else { return nil }
        if let parsed = UUID(uuidString: storedID), availableIDs.contains(parsed) {
            return parsed
        }
        return availableIDs.first
    }
}

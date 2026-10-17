import Foundation
import SwiftData

@Model
final class HistoryRecord {
    @Attribute(.unique) var id: UUID
    var kid: Kid?
    var title: String
    var delta: Int
    var timestamp: Date
    var sourceKindRaw: String
    var sourceId: String?

    var sourceKind: SourceKind {
        SourceKind(rawValue: sourceKindRaw) ?? .preset
    }

    init(
        id: UUID = UUID(),
        kid: Kid,
        title: String,
        delta: Int,
        timestamp: Date = .now,
        sourceKind: SourceKind,
        sourceId: String? = nil
    ) {
        self.id = id
        self.kid = kid
        self.title = title
        self.delta = delta
        self.timestamp = timestamp
        self.sourceKindRaw = sourceKind.rawValue
        self.sourceId = sourceId
    }
}

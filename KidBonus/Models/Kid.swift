import Foundation
import SwiftData

@Model
final class Kid {
    @Attribute(.unique) var id: UUID
    var name: String
    var age: Int
    var colorHex: String

    @Relationship(deleteRule: .cascade, inverse: \HistoryRecord.kid)
    var history: [HistoryRecord] = []

    @Relationship(deleteRule: .cascade, inverse: \Redemption.kid)
    var redemptions: [Redemption] = []

    init(id: UUID = UUID(), name: String, age: Int, colorHex: String) {
        self.id = id
        self.name = name
        self.age = age
        self.colorHex = colorHex
    }
}

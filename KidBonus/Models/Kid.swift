import Foundation
import SwiftData

@Model
final class Kid {
    @Attribute(.unique) var id: UUID
    var name: String
    var age: Int
    var colorHex: String

    // Note: history and redemptions relationships are added in Task 6, when
    // HistoryRecord and Redemption entities are defined. Forward references
    // would not compile. A subsequent fix task will append:
    //
    //   @Relationship(deleteRule: .cascade, inverse: \HistoryRecord.kid)
    //   var history: [HistoryRecord] = []
    //   @Relationship(deleteRule: .cascade, inverse: \Redemption.kid)
    //   var redemptions: [Redemption] = []
    //
    // ...once those model types land.

    init(id: UUID = UUID(), name: String, age: Int, colorHex: String) {
        self.id = id
        self.name = name
        self.age = age
        self.colorHex = colorHex
    }
}

import Foundation
import SwiftData

@Model
final class Redemption {
    @Attribute(.unique) var id: UUID
    var kid: Kid?
    var productName: String
    var cost: Int
    var timestamp: Date

    init(
        id: UUID = UUID(),
        kid: Kid,
        productName: String,
        cost: Int,
        timestamp: Date = .now
    ) {
        self.id = id
        self.kid = kid
        self.productName = productName
        self.cost = cost
        self.timestamp = timestamp
    }
}

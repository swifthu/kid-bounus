import Foundation
import SwiftData

@Model
final class PointItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var pointCost: Int
    var category: ProductCategory
    var isActive: Bool

    init(id: UUID = UUID(), title: String, pointCost: Int, category: ProductCategory, isActive: Bool = true) {
        self.id = id
        self.title = title
        self.pointCost = pointCost
        self.category = category
        self.isActive = isActive
    }
}

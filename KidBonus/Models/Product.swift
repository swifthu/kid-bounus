import Foundation
import SwiftData

@Model
final class Product {
    @Attribute(.unique) var id: UUID
    var name: String
    var category: ProductCategory
    var cost: Int
    var iconName: String?
    var desc: String

    init(id: UUID = UUID(), name: String, category: ProductCategory, cost: Int, iconName: String? = nil, desc: String) {
        self.id = id
        self.name = name
        self.category = category
        self.cost = cost
        self.iconName = iconName
        self.desc = desc
    }
}

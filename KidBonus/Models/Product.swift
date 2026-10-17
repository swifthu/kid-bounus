import Foundation
import SwiftData

@Model
final class Product {
    @Attribute(.unique) var id: UUID
    var name: String
    var pointPrice: Int
    var category: ProductCategory
    var stock: Int
    var iconName: String
    var desc: String

    init(
        id: UUID = UUID(),
        name: String,
        pointPrice: Int,
        category: ProductCategory,
        stock: Int = 0,
        iconName: String = "",
        desc: String = ""
    ) {
        self.id = id
        self.name = name
        self.pointPrice = pointPrice
        self.category = category
        self.stock = stock
        self.iconName = iconName
        self.desc = desc
    }
}

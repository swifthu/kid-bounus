import Foundation
import SwiftData

@Model
final class Product {
    @Attribute(.unique) var id: UUID
    var name: String
    var pointPrice: Int
    var category: ProductCategory
    var stock: Int

    init(id: UUID = UUID(), name: String, pointPrice: Int, category: ProductCategory, stock: Int = 0) {
        self.id = id
        self.name = name
        self.pointPrice = pointPrice
        self.category = category
        self.stock = stock
    }
}

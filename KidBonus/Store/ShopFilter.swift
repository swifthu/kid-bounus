import Foundation
import SwiftData

/// 「积分商城」的筛选与可负担性判断。
enum ShopFilter {
    /// category 为 nil 表示「全部」；结果按价格从高到低。
    static func filter(_ products: [Product], category: ProductCategory?) -> [Product] {
        let pool = category == nil ? products : products.filter { $0.category == category }
        return pool.sorted { $0.cost > $1.cost }
    }

    /// 用于「可兑换 / 还差 N」标签：取所有孩子中积分最高者。无孩子时为 0。
    static func bestPoints(_ kids: [Kid]) -> Int {
        kids.map { PointMath.kidPoints($0) }.max() ?? 0
    }

    static func shortfall(_ product: Product, points: Int) -> Int {
        max(0, product.cost - points)
    }

    static func isAffordable(_ product: Product, points: Int) -> Bool {
        points >= product.cost
    }
}

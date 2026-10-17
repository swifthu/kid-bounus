import Foundation
import SwiftData

enum SeedData {
    static func installIfEmpty(ctx: ModelContext) {
        let kids = (try? ctx.fetchCount(FetchDescriptor<Kid>())) ?? 0
        guard kids == 0 else { return }
        installFresh(ctx: ctx)
    }

    static func installFresh(ctx: ModelContext) {
        // Clear all entities
        deleteAll(of: Kid.self, ctx: ctx)
        deleteAll(of: PointItem.self, ctx: ctx)
        deleteAll(of: Product.self, ctx: ctx)
        deleteAll(of: HistoryRecord.self, ctx: ctx)
        deleteAll(of: Redemption.self, ctx: ctx)
        deleteAll(of: Streak.self, ctx: ctx)

        // Two kids
        let k1 = Kid(name: "小明", age: 8,  colorHex: "#1B365D")
        let k2 = Kid(name: "小红", age: 10, colorHex: "#4A6B3A")
        ctx.insert(k1)
        ctx.insert(k2)

        // Add items
        let adds: [PointItem] = [
            PointItem(title: "完成作业",   pointCost: 5,  kind: .add, iconName: "book",        desc: "今天作业都完成了"),
            PointItem(title: "阅读 30 分", pointCost: 5,  kind: .add, iconName: "book",        desc: "专心读书半小时"),
            PointItem(title: "整理房间",   pointCost: 3,  kind: .add, iconName: "house",       desc: "把玩具和衣服归位"),
            PointItem(title: "主动练琴",   pointCost: 8,  kind: .add, iconName: "music.note",  desc: "自己主动练了乐器"),
            PointItem(title: "帮忙家务",   pointCost: 3,  kind: .add, iconName: "hand.raised", desc: "洗碗/扫地/倒垃圾"),
            PointItem(title: "运动 30 分", pointCost: 6,  kind: .add, iconName: "figure.run",  desc: "跑跳运动半小时"),
            PointItem(title: "刷牙早晚",   pointCost: 2,  kind: .add, iconName: "checkmark",   desc: "认真刷了两次牙"),
        ]
        adds.forEach(ctx.insert)

        // Deduct items
        let ded: [PointItem] = [
            PointItem(title: "赖床迟到",   pointCost: -3, kind: .deduct, iconName: "clock",       desc: "早上赖着不肯起"),
            PointItem(title: "看电视超时", pointCost: -2, kind: .deduct, iconName: "tv",          desc: "超过约定时间"),
            PointItem(title: "顶嘴发脾气", pointCost: -5, kind: .deduct, iconName: "bubble.left",  desc: "对家人态度不好"),
            PointItem(title: "挑食",       pointCost: -2, kind: .deduct, iconName: "fork.knife",  desc: "吃饭挑三拣四"),
            PointItem(title: "忘带作业",   pointCost: -5, kind: .deduct, iconName: "tray",         desc: "作业落在家了"),
        ]
        ded.forEach(ctx.insert)

        // Products
        let products: [Product] = [
            Product(name: "乐高积木",   pointPrice: 200, category: .toy,  iconName: "puzzlepiece",   desc: "小颗粒拼装玩具"),
            Product(name: "漫画书一本", pointPrice:  80, category: .book, iconName: "book",          desc: "喜爱的系列最新一册"),
            Product(name: "冰淇淋",     pointPrice:  30, category: .food, iconName: "cone",           desc: "周末的甜点"),
            Product(name: "选电影特权", pointPrice:  50, category: .priv, iconName: "film",          desc: "今晚你决定看什么"),
            Product(name: "晚睡 30 分", pointPrice:  40, category: .priv, iconName: "moon",          desc: "允许今晚晚睡半小时"),
            Product(name: "公园出游",   pointPrice: 150, category: .out,  iconName: "tree",           desc: "周末全家去公园"),
            Product(name: "贴纸一包",   pointPrice:  25, category: .toy,  iconName: "seal",           desc: "彩色奖励贴纸"),
            Product(name: "蛋糕一块",   pointPrice:  60, category: .food, iconName: "birthday.cake", desc: "下午茶蛋糕"),
        ]
        products.forEach(ctx.insert)

        try? ctx.save()
    }

    private static func deleteAll<T: PersistentModel>(of type: T.Type, ctx: ModelContext) {
        try? ctx.delete(model: type)
    }
}

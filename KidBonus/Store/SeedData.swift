import Foundation
import SwiftData

enum SeedData {
    static func installIfEmpty(ctx: ModelContext) {
        let kids = (try? ctx.fetchCount(FetchDescriptor<Kid>())) ?? 0
        if kids == 0 {
            installFresh(ctx: ctx)
        } else {
            // 老版本没有奖励规则时补上默认的，避免升级后一直发不出 bonus
            installRulesIfMissing(ctx: ctx)
        }
    }

    /// 没有规则时写入默认的「每 7 天 +20 / 每 30 天 +100」。
    static func installRulesIfMissing(ctx: ModelContext) {
        let count = (try? ctx.fetchCount(FetchDescriptor<BonusRule>())) ?? 0
        guard count == 0 else { return }
        defaultRules().forEach(ctx.insert)
        try? ctx.save()
    }

    static func defaultRules() -> [BonusRule] {
        [
            BonusRule(days: 7, points: 20),
            BonusRule(days: 30, points: 100)
        ]
    }

    static func installFresh(ctx: ModelContext) {
        // Clear all entity stores
        deleteAll(of: Kid.self, ctx: ctx)
        deleteAll(of: PointItem.self, ctx: ctx)
        deleteAll(of: Product.self, ctx: ctx)
        deleteAll(of: BonusRule.self, ctx: ctx)
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
            PointItem(kind: .add,    title: "完成作业",   delta: 5, iconName: "book",       desc: "今天作业都完成了"),
            PointItem(kind: .add,    title: "阅读 30 分", delta: 5, iconName: "book",       desc: "专心读书半小时"),
            PointItem(kind: .add,    title: "整理房间",   delta: 3, iconName: "house",      desc: "把玩具和衣服归位"),
            PointItem(kind: .add,    title: "主动练琴",   delta: 8, iconName: "music.note", desc: "自己主动练了乐器"),
            PointItem(kind: .add,    title: "帮忙家务",   delta: 3, iconName: "hand.raised", desc: "洗碗/扫地/倒垃圾"),
            PointItem(kind: .add,    title: "运动 30 分", delta: 6, iconName: "figure.run", desc: "跑跳运动半小时"),
            PointItem(kind: .add,    title: "刷牙早晚",   delta: 2, iconName: "checkmark",  desc: "认真刷了两次牙"),
        ]
        adds.forEach(ctx.insert)

        // Deduct items
        let ded: [PointItem] = [
            PointItem(kind: .deduct, title: "赖床迟到",   delta: -3, iconName: "clock",      desc: "早上赖着不肯起"),
            PointItem(kind: .deduct, title: "看电视超时", delta: -2, iconName: "tv",         desc: "超过约定时间"),
            PointItem(kind: .deduct, title: "顶嘴发脾气", delta: -5, iconName: "bubble.left", desc: "对家人态度不好"),
            PointItem(kind: .deduct, title: "挑食",       delta: -2, iconName: "fork.knife", desc: "吃饭挑三拣四"),
            PointItem(kind: .deduct, title: "忘带作业",   delta: -5, iconName: "tray",       desc: "作业落在家了"),
        ]
        ded.forEach(ctx.insert)

        // Products
        let products: [Product] = [
            Product(name: "乐高积木",   category: .toy,  cost: 200, iconName: "puzzlepiece",   desc: "小颗粒拼装玩具"),
            Product(name: "漫画书一本", category: .book, cost:  80, iconName: "book",          desc: "喜爱的系列最新一册"),
            Product(name: "冰淇淋",     category: .food, cost:  30, iconName: "cone",          desc: "周末的甜点"),
            Product(name: "选电影特权", category: .priv, cost:  50, iconName: "film",          desc: "今晚你决定看什么"),
            Product(name: "晚睡 30 分", category: .priv, cost:  40, iconName: "moon",          desc: "允许今晚晚睡半小时"),
            Product(name: "公园出游",   category: .out,  cost: 150, iconName: "tree",          desc: "周末全家去公园"),
            Product(name: "贴纸一包",   category: .toy,  cost:  25, iconName: "seal",          desc: "彩色奖励贴纸"),
            Product(name: "蛋糕一块",   category: .food, cost:  60, iconName: "birthday.cake", desc: "下午茶蛋糕"),
        ]
        products.forEach(ctx.insert)

        // Bonus rules
        defaultRules().forEach(ctx.insert)

        try? ctx.save()
    }

    private static func deleteAll<T: PersistentModel>(of type: T.Type, ctx: ModelContext) {
        try? ctx.delete(model: type)
    }
}

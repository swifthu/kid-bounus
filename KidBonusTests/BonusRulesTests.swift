import XCTest
import SwiftData
@testable import KidBonus

/// bonus 规则：读规则、发奖匹配、规则输入校验。
@MainActor
final class BonusRulesTests: XCTestCase {
    private var container: ModelContainer!

    override func setUp() {
        super.setUp()
        let schema = Schema([Kid.self, PointItem.self, Product.self, BonusRule.self,
                             HistoryRecord.self, Redemption.self, Streak.self])
        container = try! ModelContainer(
            for: schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    override func tearDown() {
        container = nil
        super.tearDown()
    }

    private var ctx: ModelContext { container.mainContext }

    // MARK: 规则匹配

    func test没有规则时不发奖() {
        XCTAssertTrue(BonusRules.awards(for: 7, ctx: ctx).isEmpty)
    }

    func test连续天数是规则倍数时发奖() {
        ctx.insert(BonusRule(days: 5, points: 30))
        XCTAssertEqual(BonusRules.awards(for: 5, ctx: ctx), [StreakAward(days: 5, points: 30)])
        XCTAssertEqual(BonusRules.awards(for: 10, ctx: ctx), [StreakAward(days: 5, points: 30)])
        XCTAssertTrue(BonusRules.awards(for: 6, ctx: ctx).isEmpty)
    }

    func test停用的规则不发奖() {
        ctx.insert(BonusRule(days: 5, points: 30, enabled: false))
        XCTAssertTrue(BonusRules.awards(for: 5, ctx: ctx).isEmpty)
    }

    func test多条规则同时命中时都发() {
        ctx.insert(BonusRule(days: 3, points: 10))
        ctx.insert(BonusRule(days: 6, points: 20))
        let awards = BonusRules.awards(for: 6, ctx: ctx)
        XCTAssertEqual(awards, [StreakAward(days: 3, points: 10), StreakAward(days: 6, points: 20)],
                       "按天数从少到多排")
    }

    func test连续天数为0时不发奖() {
        ctx.insert(BonusRule(days: 1, points: 5))
        XCTAssertTrue(BonusRules.awards(for: 0, ctx: ctx).isEmpty)
    }

    func test启用中的规则按天数排序() {
        ctx.insert(BonusRule(days: 30, points: 100))
        ctx.insert(BonusRule(days: 7, points: 20))
        ctx.insert(BonusRule(days: 14, points: 50, enabled: false))
        let active = BonusRules.active(ctx: ctx)
        XCTAssertEqual(active.map(\.days), [7, 30], "停用的规则不参与排序")
    }

    // MARK: 规则输入校验

    func test合法输入() throws {
        let draft = try BonusRuleValidator.validate(daysText: " 7 ", pointsText: "20")
        XCTAssertEqual(draft, BonusRuleDraft(days: 7, points: 20))
    }

    func test奖励为零分报错() {
        // 0 分的规则只会多一条 +0 的历史记录，没有任何提示，没意义
        XCTAssertThrowsError(try BonusRuleValidator.validate(daysText: "7", pointsText: "0")) {
            XCTAssertEqual($0 as? BonusRuleValidationError, .invalidPoints)
        }
    }

    func test天数为空报错() {
        XCTAssertThrowsError(try BonusRuleValidator.validate(daysText: "", pointsText: "10")) {
            XCTAssertEqual($0 as? BonusRuleValidationError, .emptyDays)
        }
    }

    func test天数为非正数报错() {
        for text in ["0", "-3", "abc"] {
            XCTAssertThrowsError(try BonusRuleValidator.validate(daysText: text, pointsText: "10")) {
                XCTAssertEqual($0 as? BonusRuleValidationError, .invalidDays)
            }
        }
    }

    func test奖励为空报错() {
        XCTAssertThrowsError(try BonusRuleValidator.validate(daysText: "7", pointsText: "")) {
            XCTAssertEqual($0 as? BonusRuleValidationError, .emptyPoints)
        }
    }

    func test奖励为负数报错() {
        XCTAssertThrowsError(try BonusRuleValidator.validate(daysText: "7", pointsText: "-1")) {
            XCTAssertEqual($0 as? BonusRuleValidationError, .invalidPoints)
        }
    }

    // MARK: 重复周期

    func test同一周期不能有两条规则() {
        let rule = BonusRule(days: 7, points: 20)
        ctx.insert(rule)
        XCTAssertTrue(BonusRules.hasRule(days: 7, excluding: nil, ctx: ctx))
        XCTAssertFalse(BonusRules.hasRule(days: 7, excluding: rule.id, ctx: ctx),
                       "编辑自己不算重复")
        XCTAssertFalse(BonusRules.hasRule(days: 14, excluding: nil, ctx: ctx))
    }
}

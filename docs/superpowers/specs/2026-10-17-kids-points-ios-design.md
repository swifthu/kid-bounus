# 双娃积分 · iOS App 设计文档

- 日期：2026-10-17
- 状态：待批准
- 范围：完整复刻 6 个页面，原型来源 `design/儿童积分激励系统设计/`
- 目标：把现有 HTML+CSS+JS 网页原型 1:1 移植到 iOS 原生应用

## 1. 背景与目标

`design/儿童积分激励系统设计/index.html` + `app.js` 已经交付了一个手机壳（390×844）下的网页原型，叫「双娃积分」/「双娃成长系统」，主题是给两个孩子的积分激励 App：

- 记录每次加分/扣分（预设项 + 自定义）
- 连续打卡 streak 触发 bonus
- 商品商城用积分兑换
- 时间轴、统计图、管理设置

用户决定把这份原型 1:1 移植成 SwiftUI iOS 原生 App，技术栈在头脑风暴中已确定。

## 2. 技术栈与平台目标

| 项 | 决策 |
|----|------|
| 平台 | iOS 18.0+（iPhone，可横竖屏，重点竖屏） |
| 语言/框架 | Swift 6 / SwiftUI（iOS 18+ Tab Section、SF Symbols 6、Swift Charts） |
| 持久化 | SwiftData（@Model + ModelContainer + @Query） |
| 路由 | iOS 18 `TabView` + 内部状态切换 + `.sheet` / `.confirmationDialog` |
| 字体 | 霞鹜文楷 LXGW WenKai（Light + Regular）— SIL OFL 1.1 |
| 多设备同步 | 不需要（本地 SwiftData） |
| 项目组织 | 单 Xcode project，单 App target，按文件夹分模块 |
| 测试 | 业务逻辑单测（PointMath / Streak / Trend / Seed），UI 用 #Preview |
| App 显示名 | 成长树（默认），英文名 GrowingTree，Bundle ID `com.kidbonus.growingtree` |
| 设计系统名 | kami（沿用原型命名） |

## 3. 功能范围（来自原型 6 个页面）

### 3.1 首页 Home
- 标题栏：左 `00 · 成长树`，右两个 icon-button（统计 + 我的）
- 头部提示行：今天日期的中文格式
- 两个 KidCard：当前积分、今日净分、连续天数、bonus 状态
- 快捷加减分按钮对（+ / −）

### 3.2 加减分 Quick
- 顶部两个 Kid 切换 tab
- 加分项 list（每项带 +delta）
- 扣分项 list
- "手动加减分"入口 → 弹层（标题、分值、备注、最近 5 条自定义 chip 一键再用）

### 3.3 历程 History
- 筛选 chip（全部 / 孩子1 / 孩子2）
- 时间轴：按天分组（今天/昨天/×月×日），每条带 add/deduct dot、标题、子标签、+/-delta

### 3.4 商城 Shop
- 分类 chip（全部 / 玩具 / 图书 / 零食 / 特权 / 外出）
- 商品 grid（不可兑换的标灰，显示还差多少分）
- 兑换 → Sheet 选孩子 → 扣分 → Toast

### 3.5 统计 Stats
- 孩子切换
- 3 个数字块：当前积分、加分次数、扣分次数
- 近 14 天每日净积分趋势图（Swift Charts `LineMark`）
- 按项目维度分布 top 8（+次数 · −次数）

### 3.6 我的 Me
- 01 段：两个孩子可改名（input 实时同步）
- 02 段：加分项 list，可删除（confirm 后移除）
- 03 段：扣分项 list
- 04 段：增加加分/扣分项按钮 + 重置全部数据按钮

### 3.7 跨页行为
- 加分时检测 streak：当日首次加分触发 `bumpStreak`，count=7 → +20 分自动记录 / count=30 → 再 +100 分（30 = 7 + bonus 续期）
- 加分时数字回弹动画（可选）
- Toast：`+5 分 · 当前 158 分`
- BottomSheet：底部抽屉式（iOS 16+ 有原生 `.sheetPresentationDetents`，做中等高度 `medium`）

## 4. 数据模型（SwiftData @Model）

```swift
@Model class Kid {
    var id: UUID
    var name: String
    var age: Int
    var colorHex: String
    @Relationship(deleteRule: .cascade)
    var history: [HistoryRecord]
    @Relationship(deleteRule: .cascade)
    var redemptions: [Redemption]
    var streak: Streak?
}

@Model class PointItem {           // 预设加减项
    var id: UUID
    var kind: Kind                  // .add / .deduct
    var title: String
    var delta: Int                  // +N or -N
    var iconName: String?           // 系统 SF Symbol 名
    var desc: String
}

@Model class Product {             // 商城商品
    var id: UUID
    var name: String
    var category: Category          // .toy / .book / .food / .priv / .out
    var cost: Int
    var iconName: String?
    var desc: String
}

@Model class HistoryRecord {       // 加减分记录
    var id: UUID
    var kid: Kid?                   // 关系
    var title: String
    var delta: Int
    var timestamp: Date
    var sourceKind: SourceKind      // .preset / .freeform / .streakBonus
    var sourceId: String?           // preset itemId / freeform-... / streak-bonus
}

@Model class Redemption {          // 兑换记录
    var id: UUID
    var kid: Kid?
    var productName: String
    var cost: Int
    var timestamp: Date
}

@Model class Streak {
    var count: Int
    var lastDateKey: String?        // "2026-10-17"
}
```

### 4.1 派生计算（不存，只算）
- `kidPoints(kid)` = sum(history.delta) − sum(redemption.cost)
- `todayDelta(kid)` = sum(history.delta where dayKey(timestamp)==today)
- `trend(kid, days)` = 近 N 天每日净积分

## 5. 主题：kami 系统（SwiftUI 翻译）

| Token | CSS 值 | SwiftUI |
|-------|--------|---------|
| `--bg` | `#f5f4ed` | `Color.kami.bg` |
| `--surface` | `#faf9f5` | `Color.kami.surface` |
| `--surface-warm` | `#e8e6dc` | `Color.kami.surfaceWarm` |
| `--fg` | `#141413` | `Color.kami.fg` |
| `--muted` | `#504e49` | `Color.kami.muted` |
| `--meta` | `#6b6a64` | `Color.kami.meta` |
| `--accent` | `#1b365d` | `Color.kami.accent` |
| `--success` | `#4a6b3a` | `Color.kami.success` |
| `--danger` | `#8a3a30` | `Color.kami.danger` |
| `--warn` | `#8a6b1f` | `Color.kami.warn` |
| `--radius-md` | `8px` | `Radius.md` |
| 类型 | serif（TsangerJinKai02 替身 LXGW WenKai） | `Font.kami.body` |
| 间距 | 4 / 8 / 12 / 16 / 20 / 24 / 32 | `Spacing.s1..s8` |

文件： `KidBonus/Theme/KamiTokens.swift`，整体一个 `enum` 命名空间。

## 6. 视图结构

```
ContentView (TabView, 4 user tabs)
├── HomeTab       → HomeView
├── QuickTab      → QuickView
├── ShopTab       → ShopView
├── HistoryTab    → HistoryView
├── MeTab         → MeView
└── (StatsView 由 top-bar "今日概览" 按钮 push 到独立导航栈, 不占 tab)

Sheets (present modally over current tab)
├── ManualRecordSheet
├── AddItemSheet
└── RedeemConfirmSheet
```

说明：原型底部 tab 只有 5 个（首页/加减/商城/历程/我的），统计是从顶部 icon-button 进入。我严格沿用原型结构，避免无端扩大 tab 数量。

### 6.1 共享组件
- `KidAvatar` — 圆形 26/36/44px 自适应，孩子名末两字
- `KidTabs` — 两段式 segmented
- `ItemRow` — 一行：icon + 标题 + sub + delta
- `ProductCard` — 图标方形 + 名字 + 价格 + 可兑换 tag
- `TimelineRow` — 时间轴一行
- `StatBlock` — 大数字 + 标签
- `SheetScaffold` — 弹层统一容器（grab + title + content + actions）
- `ToastBanner` — 顶部 4 秒 toast
- `KamiButton` — Primary / Secondary

## 7. 关键交互

### 7.1 加分流程
1. QuickTab 点 ItemRow → `RecordStore.add(kid, item)`
2. `add` 写一条 `HistoryRecord`，sourceKind=.preset
3. 调 `StreakEngine.bump(kid, on: today)` 返回 `{streak, bonus}`
4. 若 bonus > 0，再写一条 `HistoryRecord`，sourceKind=.streakBonus，delta=bonus
5. Toast 显示：`{kid.name} · {item.title}` + `+5 分 · 当前 158 分`
6. 若有 bonus，700ms 后第二条 Toast 显示 `Streak bonus! 连续 7 天 · +20 分`
7. SwiftData 自动持久化；所有监听该 kid 的视图（Home / History / Stats）通过 `@Query` 自动更新

### 7.2 streak bonus 规则
- 每日首次加分时检查
- 当日已加分直接返回 `{streak: existing, bonus: 0}`
- 否则：lastDate==昨天 → count++；否则 count=1
- count==7 → bonus=20；count==30 → bonus 续期再 +100

### 7.3 兑换流程
1. Shop 点 ProductCard → 若某 kid 积分够 → 打开 RedeemConfirmSheet
2. Sheet 内 select kid；当前 kid 默认；若积分不够则灰显但仍可选
3. 确认 → 检查积分 → 写 `Redemption` → Toast
4. 不足则 Toast 报 `积分不足`

### 7.4 自定义加减（Manual Sheet）
- 复用 OpenDesign 的 sheet 设计：标题、分值（带 ± 切换按钮）、备注
- 「最近 5 条自定义」chip 阵列：点 chip = 直接加分（带 kid 切换）
- 写入 sourceKind=.freeform，sourceId=`freeform-{timestamp}`

### 7.5 重置数据
- MeTab 最底一个危险按钮 `重置全部数据`
- 弹 confirmDialog → 删 ModelContainer 内全部 record，重 seed SEED 数据

## 8. 状态管理

| 状态 | 位置 | 持久化 |
|------|------|--------|
| 当前 kid ID | `@AppStorage("currentKidId")` | UserDefaults |
| 当前 tab | 由 TabView 自动管理 | 不持久（启动回 home） |
| 历史筛选 | `HistoryView` `@State` | 不持久 |
| 商城分类 | `ShopView` `@State` | 不持久 |
| 表单 input | 各 sheet `@State` | 不持久 |
| 数据实体 | SwiftData | 自动 |

`AppState` 控制器提供 `currentKidID` 和切换方法，让 `@AppStorage` 与 SwiftData 联动。

## 9. 字体方案

### 9.1 资源
- `KidBonus/Resources/Fonts/LXGWWenKai-Regular.ttf`
- `KidBonus/Resources/Fonts/LXGWWenKai-Light.ttf`

来源：GitHub `lxgw/LxgwWenKai` release（OFL）。

### 9.2 注册
- 在 Xcode Build Phases → Copy Bundle Resources 加入 .ttf
- `Info.plist` 加 `UIAppFonts: [LXGWWenKai-Regular.ttf, LXGWWenKai-Light.ttf]`

### 9.3 使用
```swift
extension Font {
    static func kami(_ style: KamiFontStyle = .body, size: CGFloat) -> Font {
        switch style {
        case .display: return .custom("LXGWWenKai-Light", size: size, relativeTo: .title)
        case .body:    return .custom("LXGWWenKai-Regular", size: size, relativeTo: .body)
        case .mono:    return .system(size: size, design: .monospaced)
        }
    }
}
```

### 9.4 许可文本
- `KidBonus/Resources/Fonts/OFL.txt`（来自上游 LICENSE）
- 关于页放一行："本应用包含「霞鹜文楷」字体，遵循 SIL Open Font License 1.1"

## 10. 测试策略

`KidBonusTests/`（XCTest）：

- `PointMathTests` — 历史+兑换求和、跨日 todayDelta
- `StreakEngineTests` — 同日二次加分不重复计数、隔 1 天连续 +1、断签重置、count==7 bonus
- `TrendBuilderTests` — 14 天桶对齐、空状态、补 0
- `SeedDataTests` — seed kids/items/products 不为空、SEED 幂等

UI 用 `#Preview` 渲染各页面，状态种子来自 in-memory `ModelContainer(isStoredInMemoryOnly: true)`。

## 11. 项目文件清单

```
/Volumes/CC/Projects/kid-bounus/
├── KidBonus.xcodeproj
├── KidBonus/
│   ├── App/KidBonusApp.swift                    # @main + ModelContainer
│   ├── Theme/
│   │   ├── KamiTokens.swift                    # 颜色/字体/间距
│   │   └── Font+.swift                          # Font.kami(...)
│   ├── Models/
│   │   ├── Kid.swift
│   │   ├── PointItem.swift
│   │   ├── Product.swift
│   │   ├── HistoryRecord.swift
│   │   ├── Redemption.swift
│   │   └── Streak.swift
│   ├── Store/
│   │   ├── AppState.swift                       # currentKid
│   │   ├── PointMath.swift                      # kidPoints / todayDelta
│   │   ├── StreakEngine.swift                   # streak bonus
│   │   ├── TrendBuilder.swift                   # 14 天
│   │   ├── SeedData.swift                       # SEED constants
│   │   └── RecordStore.swift                    # 写入 history/redemption
│   ├── Views/
│   │   ├── ContentView.swift                    # 5-tab 容器
│   │   ├── Home/HomeView.swift
│   │   ├── Home/KidCard.swift
│   │   ├── Quick/QuickView.swift
│   │   ├── Quick/ItemRow.swift
│   │   ├── History/HistoryView.swift
│   │   ├── Shop/ShopView.swift
│   │   ├── Shop/ProductCard.swift
│   │   ├── Stats/StatsView.swift
│   │   ├── Stats/Sparkline.swift                # Swift Charts LineMark
│   │   ├── Me/MeView.swift
│   │   ├── Components/                          # 共享
│   │   │   ├── KidAvatar.swift
│   │   │   ├── KidTabs.swift
│   │   │   ├── Tag.swift
│   │   │   ├── SheetScaffold.swift
│   │   │   ├── Toast.swift
│   │   │   └── KamiButton.swift
│   │   └── Sheets/
│   │       ├── ManualRecordSheet.swift
│   │       ├── AddItemSheet.swift
│   │       └── RedeemConfirmSheet.swift
│   ├── Resources/
│   │   ├── Assets.xcassets/                     # AppIcon、AccentColor
│   │   └── Fonts/
│   │       ├── LXGWWenKai-Regular.ttf
│   │       ├── LXGWWenKai-Light.ttf
│   │       └── OFL.txt
│   └── Info.plist                               # UIAppFonts 注册
├── KidBonusTests/
│   ├── PointMathTests.swift
│   ├── StreakEngineTests.swift
│   ├── TrendBuilderTests.swift
│   └── SeedDataTests.swift
└── README.md
```

## 12. 实施顺序（高层 milestone）

1. **脚手架**：Xcode project + App target + Tests target；kami tokens；字体注册；空 ContentView 启动
2. **Model 层**：SwiftData @Model 6 个 + 种子数据；ModelContainer 注入环境
3. **数据层**：PointMath / StreakEngine / TrendBuilder / RecordStore 写完 + 单测通过
4. **共享组件**：KidAvatar / Tag / KamiButton / SheetScaffold / Toast
5. **首页 Quick**：KidCard / ItemRow / 写分流程 + Toast
6. **历程 + 商城**：时间轴、ProductCard、RedeemConfirmSheet
7. **统计**：3 stat blocks + Swift Charts LineMark + 项目分布
8. **我的**：改名、增删项、重置
9. **手动加减 + 增加项 sheet**
10. **打磨细节**：动画、空态、错误态、深色模式适配（采用 kami 在深色下的微调）
11. **README + 启动说明**

每个 milestone 跑 build + 测试，给 emoji 显示状态再进入下一步。

## 13. 风险与权衡

- **Streak 跨时区**：原型按本地日期 key，iOS 也按本地，但用户时区变化可能导致记录日期错位。先实现「本地日」版本，留 TODO 处理时区切换。
- **深色模式**：原型未提供暗色版。v1 锁定 Light mode（`ColorScheme` 强制 light），后续在 v2 单独设计暗色。
- **首次启动空态**：当 SwiftData 内无数据（用户主动重置过），通过 `SeedData.installIfEmpty(ctx)` 重新塞种子。
- **字体下载大小**：霞鹜文楷一个 TTF 约 6–10 MB，App 总安装体积增加可控。如果未来要瘦身，可只塞 Regular + Mono。
- **SwiftData Migration**：v1 阶段不引入 schema 版本概念，所有 model 是首次；后续如调整字段用 `VersionedSchema`。

## 14. 不做（YAGNI）

- iCloud / CloudKit 同步
- Apple Watch / Widget / Live Activity
- 通知提醒（定时打卡 push）
- 多家庭 / 账号体系
- 暗黑模式独立设计（v2）
- 多语言（先中文）
- App Store 上架所需的多分辨率截图 / 元数据（README 里给步骤即可）

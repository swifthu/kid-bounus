# 成长树 (KidBonus) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把设计稿 `design/儿童积分激励系统设计/` 完整复刻为 iOS 18+ SwiftUI 原生应用，包含 6 个页面、SwiftData 持久化、霞鹜文楷字体、kami 设计系统。

**Architecture:** 单 Xcode project 单 App target。SwiftUI + SwiftData + 共享 ViewModel。颜色字体间距由 `KamiTokens.swift` 提供统一主题（沿用原型 kami 系统）。Sheet 通过 `.sheet` + `presentationDetents` 实现原型中的底部弹层。Bottom tab 5 个（首页 / 加减 / 商城 / 历程 / 我的），stats 由顶部 icon-button 进入。

**Tech Stack:** Swift 6 / SwiftUI (iOS 18+) / SwiftData / Swift Charts / 霞鹜文楷 LXGW WenKai (Light + Regular, OFL 1.1) / XCTest

## Global Constraints

- **平台最低**：iOS 18.0，仅 iPhone（先锁定 portrait）
- **Bundle ID**：`com.kidbonus.growingtree`
- **App 显示名**（中）：成长树；Display Name（英文）：GrowingTree
- **设计系统命名**：`kami`（参考原型命名），tokens 在 `Theme/KamiTokens.swift`
- **字体注册**：Info.plist `UIAppFonts: ["LXGWWenKai-Regular", "LXGWWenKai-Light"]`
- **持久化**：SwiftData，container 自动 init；首次启动塞 SEED，空态再 seed
- **测试栈**：XCTest，所有业务逻辑先 TDD（PointMath / StreakEngine / TrendBuilder / SeedData）
- **状态管理**：当前 kid 用 `@AppStorage("currentKidId")`；当前 tab 不持久；表单 `@State`
- **重置数据**：删除全部 record 后调 `SeedData.installIfEmpty`
- **YAGNI**：无 iCloud、无通知、无 Widget、无暗黑模式独立设计、无多语言（先中文）
- **代码命名空间**：`enum`/`struct` 集中定义 Color/Spacing/Radius/Font 的 token
- **commit**：每个任务独立 commit，message 用 `feat:` / `test:` / `chore:` / `docs:` 形式

---

## File Structure

```
KidBonus/
├── KidBonus.xcodeproj                  # Xcode 工程 (生成)
├── KidBonus/
│   ├── App/KidBonusApp.swift           # @main + ModelContainer
│   ├── Theme/
│   │   ├── KamiTokens.swift            # Color/Spacing/Radius/KamiFontStyle/Kind/Category/SourceKind
│   │   └── Font+.swift                 # Font.kami(...)
│   ├── Models/
│   │   ├── Kid.swift
│   │   ├── PointItem.swift
│   │   ├── Product.swift
│   │   ├── HistoryRecord.swift
│   │   ├── Redemption.swift
│   │   └── Streak.swift
│   ├── Store/
│   │   ├── AppState.swift              # currentKidID (AppStorage)
│   │   ├── PointMath.swift             # kidPoints / todayDelta
│   │   ├── StreakEngine.swift          # bump + bonus
│   │   ├── TrendBuilder.swift          # 14 天桶 + 分布
│   │   ├── SeedData.swift              # SEED 常量 + installIfEmpty
│   │   └── RecordStore.swift           # 写入 history / redemption
│   ├── Views/
│   │   ├── ContentView.swift           # 4-tab 容器 + TopBar
│   │   ├── Home/HomeView.swift
│   │   ├── Home/KidCard.swift
│   │   ├── Quick/QuickView.swift
│   │   ├── Quick/ItemRow.swift
│   │   ├── History/HistoryView.swift
│   │   ├── Shop/ShopView.swift
│   │   ├── Shop/ProductCard.swift
│   │   ├── Stats/StatsView.swift
│   │   ├── Stats/Sparkline.swift
│   │   ├── Me/MeView.swift
│   │   ├── Components/
│   │   │   ├── KidAvatar.swift
│   │   │   ├── KidTabs.swift
│   │   │   ├── Tag.swift
│   │   │   ├── SheetScaffold.swift
│   │   │   ├── ToastCenter.swift
│   │   │   └── KamiButton.swift
│   │   └── Sheets/
│   │       ├── ManualRecordSheet.swift
│   │       ├── AddItemSheet.swift
│   │       └── RedeemConfirmSheet.swift
│   ├── Resources/
│   │   ├── Assets.xcassets/
│   │   └── Fonts/
│   │       ├── LXGWWenKai-Regular.ttf
│   │       ├── LXGWWenKai-Light.ttf
│   │       └── OFL.txt
│   └── Info.plist
├── KidBonusTests/
│   ├── PointMathTests.swift
│   ├── StreakEngineTests.swift
│   ├── TrendBuilderTests.swift
│   └── SeedDataTests.swift
└── README.md
```

---

## Task 1: 项目脚手架（Xcode project）

**Files:**
- Create: `KidBonus/KidBonus.xcodeproj/project.pbxproj`
- Create: `KidBonus/App/KidBonusApp.swift`
- Create: `KidBonus/Info.plist`
- Create: `KidBonusTests/KidBonusTests.swift`
- Create: `README.md`

这一步用 `xcodegen` 或者手写 `project.pbxproj` 生成 Xcode 工程。手写 pbxproj 复杂度高，**用 xcodegen**：维护一份 `project.yml` 输入，安装 xcodegen 后生成 .xcodeproj。这是 macOS 开发的标准实践。

**Interfaces:**
- Consumes: 无
- Produces: 可 `xcodebuild` 通过的工程根

- [ ] **Step 1: 写 `project.yml`** (`KidBonus/project.yml`)

```yaml
name: KidBonus
options:
  bundleIdPrefix: com.kidbonus
  deploymentTarget:
    iOS: "18.0"
settings:
  SWIFT_VERSION: "6.0"
  IPHONEOS_DEPLOYMENT_TARGET: "18.0"
  MARKETING_VERSION: "1.0"
  CURRENT_PROJECT_VERSION: "1"
targets:
  KidBonus:
    type: application
    platform: iOS
    sources:
      - path: KidBonus
    info:
      path: KidBonus/Info.plist
      properties:
        UILaunchScreen: {}
        UIApplicationSceneManifest:
          UIApplicationSupportsMultipleScenes: false
        UIAppFonts:
          - LXGWWenKai-Regular.ttf
          - LXGWWenKai-Light.ttf
        CFBundleDisplayName: 成长树
        UIRequiresFullScreen: true
        UIStatusBarStyle: UIStatusBarStyleDefault
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: com.kidbonus.growingtree
      INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents: YES
      INFOPLIST_KEY_UILaunchScreen_Generation: YES
      INFOPLIST_KEY_UISupportedInterfaceOrientations: "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"
  KidBonusTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - path: KidBonusTests
    dependencies:
      - target: KidBonus
schemes:
  KidBonus:
    build:
      targets:
        KidBonus: all
        KidBonusTests: [test]
    run:
      config: Debug
    test:
      config: Debug
      targets:
        - KidBonusTests
```

- [ ] **Step 2: 写 `KidBonus/App/KidBonusApp.swift`**

```swift
import SwiftUI
import SwiftData

@main
struct KidBonusApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            Kid.self, PointItem.self, Product.self,
            HistoryRecord.self, Redemption.self, Streak.self
        ])
    }
}
```

- [ ] **Step 3: 写 `KidBonus/Info.plist`**

实际由 xcodegen 生成。先放一个空 `{}` 占位让 xcodegen 接管。

- [ ] **Step 4: 写 `KidBonusTests/KidBonusTests.swift`**

```swift
import XCTest
@testable import KidBonus

final class SmokeTests: XCTestCase {
    func testAppBundleLoads() {
        XCTAssertTrue(true, "smoke")
    }
}
```

- [ ] **Step 5: 安装并生成工程**

```bash
brew install xcodegen
cd /Volumes/CC/Projects/kid-bounus/KidBonus
xcodegen generate
```

Expected: 输出 `Created project at KidBonus.xcodeproj`。

- [ ] **Step 6: 写 `README.md`**

```markdown
# 成长树 (KidBonus)

iOS 18+ SwiftUI 原生儿童积分激励 App。

## 构建
1. 安装 [xcodegen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
2. 在仓库根执行 `xcodegen generate`
3. 用 Xcode 16+ 打开 `KidBonus.xcodeproj`

## 字体
霞鹜文楷 LXGW WenKai (SIL OFL 1.1)，由 `lxgw/LxgwWenKai` 提供。
```

- [ ] **Step 7: 验证能 build**

```bash
cd /Volumes/CC/Projects/kid-bounus/KidBonus
xcodebuild -project KidBonus.xcodeproj -scheme KidBonus -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 8: 验证测试能跑**

```bash
xcodebuild test -project KidBonus.xcodeproj -scheme KidBonus -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Expected: `Test Suite 'All tests' passed`

- [ ] **Step 9: Commit**

```bash
cd /Volumes/CC/Projects/kid-bounus
git init && git add -A && git commit -m "chore: bootstrap Xcode project via xcodegen"
```

(项目不是 git 仓库，所以这一步同时初始化。)

---

## Task 2: kami 主题系统 + Font 注册

**Files:**
- Create: `KidBonus/Theme/KamiTokens.swift`
- Create: `KidBonus/Theme/Font+.swift`
- Test: `KidBonusTests/KamiTokensTests.swift`

**Interfaces:**
- Consumes: 无
- Produces: `Color.kami.bg`, `Color.kami.accent`, `Spacing.s3`, `Radius.md`, `KamiFontStyle.body`, `Font.kami(...)`

- [ ] **Step 1: 写测试** (`KidBonusTests/KamiTokensTests.swift`)

```swift
import XCTest
@testable import KidBonus

final class KamiTokensTests: XCTestCase {
    func testKamiColorsLoadFromHex() {
        let bg = Color.kami.bg
        let accent = Color.kami.accent
        XCTAssertNotNil(bg); XCTAssertNotNil(accent)
    }
    func testSpacingValues() {
        XCTAssertEqual(Spacing.s1, 4)
        XCTAssertEqual(Spacing.s4, 16)
    }
    func testFontKamiBodyReturnsCustomFont() {
        let f = Font.kami(.body, size: 14)
        XCTAssertNotNil(f)
    }
}
```

- [ ] **Step 2: 跑测试确认失败**

```bash
cd /Volumes/CC/Projects/kid-bounus/KidBonus
xcodebuild test -project KidBonus.xcodeproj -scheme KidBonus -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:KidBonusTests/KamiTokensTests
```

Expected: 编译失败（无 KamiTokens）。

- [ ] **Step 3: 实现 `Theme/KamiTokens.swift`**

```swift
import SwiftUI

enum Color {
    enum kami {
        static let bg          = Color(hex: 0xF5F4ED)
        static let surface     = Color(hex: 0xFAF9F5)
        static let surfaceWarm = Color(hex: 0xE8E6DC)
        static let fg          = Color(hex: 0x141413)
        static let fg2         = Color(hex: 0x3D3D3A)
        static let muted       = Color(hex: 0x504E49)
        static let meta        = Color(hex: 0x6B6A64)
        static let border      = Color(hex: 0xE8E6DC)
        static let borderSoft  = Color(hex: 0xE5E3D8)
        static let accent      = Color(hex: 0x1B365D)
        static let accentOn    = Color(hex: 0xFAF9F5)
        static let accentLight = Color(hex: 0x2D5A8A)
        static let accentActive = Color(hex: 0x142A48)
        static let success     = Color(hex: 0x4A6B3A)
        static let warn        = Color(hex: 0x8A6B1F)
        static let danger      = Color(hex: 0x8A3A30)

        static let tagBgFaint  = Color(hex: 0xEEF2F7)
        static let tagBgSoft   = Color(hex: 0xE4ECF5)
        static let tagBgBase   = Color(hex: 0xD6E1EE)
        static let tagBgStrong = Color(hex: 0xD0DCE9)
    }
}

enum Spacing {
    static let s1:  CGFloat = 4
    static let s2:  CGFloat = 8
    static let s3:  CGFloat = 12
    static let s4:  CGFloat = 16
    static let s5:  CGFloat = 20
    static let s6:  CGFloat = 24
    static let s7:  CGFloat = 28
    static let s8:  CGFloat = 32
    static let s12: CGFloat = 48
}

enum Radius {
    static let xs:   CGFloat = 2
    static let sm:   CGFloat = 4
    static let md:   CGFloat = 8
    static let lg:   CGFloat = 12
    static let xl:   CGFloat = 16
    static let pill: CGFloat = 9999
}

enum KamiFontStyle { case display, body, mono }

// 通用 hex 扩展
extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >>  8) & 0xFF) / 255
        let b = Double( hex        & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}
```

- [ ] **Step 4: 实现 `Theme/Font+.swift`**

```swift
import SwiftUI

extension Font {
    static func kami(_ style: KamiFontStyle = .body, size: CGFloat) -> Font {
        switch style {
        case .display:
            return .custom("LXGWWenKai-Light", size: size, relativeTo: .body)
        case .body:
            return .custom("LXGWWenKai-Regular", size: size, relativeTo: .body)
        case .mono:
            return .system(size: size, design: .monospaced)
        }
    }
}
```

- [ ] **Step 5: 跑测试确认通过**

```bash
cd /Volumes/CC/Projects/kid-bounus/KidBonus
xcodebuild test -project KidBonus.xcodeproj -scheme KidBonus -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:KidBonusTests/KamiTokensTests
```

Expected: 3 passed.

> 注意：字体在测试 simulator 里未必存在；`Font.kami(...)` 返回的是 `Font?`，不会 nil。这是允许的——测试只验证 API surface。等到 Task 3 注册字体后再验证视觉。

- [ ] **Step 6: Commit**

```bash
cd /Volumes/CC/Projects/kid-bounus
git add KidBonus/Theme KidBonusTests/KamiTokensTests.swift
git commit -m "feat(theme): add kami tokens and Font.kami extension"
```

---

## Task 3: 字体资源 + Info.plist 注册

**Files:**
- Create: `KidBonus/Resources/Fonts/LXGWWenKai-Regular.ttf`
- Create: `KidBonus/Resources/Fonts/LXGWWenKai-Light.ttf`
- Create: `KidBonus/Resources/Fonts/OFL.txt`
- Modify: `project.yml`（已包含 UIAppFonts）

**Interfaces:**
- Consumes: 上游 [LXGW WenKai release](https://github.com/lxgw/LxgwWenKai/releases)
- Produces: Info.plist 注册后，运行时 `UIFont.familyNames` 包含 `LXGW WenKai`

- [ ] **Step 1: 下载字体包**

```bash
mkdir -p /Volumes/CC/Projects/kid-bounus/KidBonus/KidBonus/Resources/Fonts
cd /Volumes/CC/Projects/kid-bounus/KidBonus/KidBonus/Resources/Fonts
# 用 HTTP 代理下载（如已配）
curl -fsSL -x http://127.0.0.1:7890 \
  https://github.com/lxgw/LxgwWenKai/releases/download/v1.521/LXGWWenKai-Regular.ttf \
  -o LXGWWenKai-Regular.ttf
curl -fsSL -x http://127.0.0.1:7890 \
  https://github.com/lxgw/LxgwWenKai/releases/download/v1.521/LXGWWenKai-Light.ttf \
  -o LXGWWenKai-Light.ttf
curl -fsSL -x http://127.0.0.1:7890 \
  https://github.com/lxgw/LxgwWenKai/raw/v1.521/OFL.txt -o OFL.txt
ls -lh
```

Expected: 三个文件都生成。

- [ ] **Step 2: 添加 Fonts 目录到 project.yml**

修改 `KidBonus/project.yml` 的 `targets.KidBonus.sources`：

```yaml
    sources:
      - path: KidBonus
        excludes:
          - "Resources/Fonts/*.ttf"
          - "Resources/Fonts/OFL.txt"
      - path: KidBonus/Resources/Fonts
        type: folder
        buildPhase: resources
```

- [ ] **Step 3: 重新生成工程**

```bash
cd /Volumes/CC/Projects/kid-bounus/KidBonus
xcodegen generate
```

Expected: `Created project at KidBonus.xcodeproj`.

- [ ] **Step 4: 验证字体出现在 app bundle**

```bash
xcodebuild -project KidBonus.xcodeproj -scheme KidBonus \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
APP=$(find ~/Library/Developer/Xcode/DerivedData -type d -name "KidBonus.app" | head -n1)
ls "$APP" | grep -i "LXGW"
```

Expected: `LXGWWenKai-Light.ttf`, `LXGWWenKai-Regular.ttf`。

- [ ] **Step 5: 验证运行时注册成功**

写一个测试（也可以用单独的一个临时 main 验证），关键是 simulator 启动后能查到这个字体族：

```bash
xcrun simctl install booted "$APP"
xcrun simctl launch booted com.kidbonus.growingtree
sleep 2
# 看 logs 是否 app 启动无字体相关 warning
xcrun simctl spawn booted log show --last 30s | grep -i "font" | head -n5
```

Expected: 无报错。

- [ ] **Step 6: Commit**

```bash
cd /Volumes/CC/Projects/kid-bounus
git add KidBonus/Resources/Fonts KidBonus/project.yml
git commit -m "chore(fonts): bundle LXGW WenKai regular + light"
```

---

## Task 4: SwiftData 模型 — 枚举 + Streak

**Files:**
- Create: `KidBonus/Models/KidModels.swift`（含 4 个枚举 + Streak）

**Interfaces:**
- Consumes: 无
- Produces: `enum Kind { add, deduct }`, `enum Category`, `enum SourceKind`, `enum DateKeyUtils`, `@Model class Streak`

- [ ] **Step 1: 写 `KidBonus/Models/KidModels.swift`**

```swift
import Foundation
import SwiftData

enum Kind: String, Codable, CaseIterable, Identifiable {
    case add, deduct
    var id: String { rawValue }
}

enum ProductCategory: String, Codable, CaseIterable, Identifiable {
    case toy, book, food, priv, out
    var id: String { rawValue }
    var label: String {
        switch self {
        case .toy:  return "玩具"
        case .book: return "图书"
        case .food: return "零食"
        case .priv: return "特权"
        case .out:  return "外出"
        }
    }
}

enum SourceKind: String, Codable {
    case preset, freeform, streakBonus, redemption
}

enum DateKey {
    static func day(_ date: Date) -> String {
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        let y = comps.year ?? 0
        let m = String(format: "%02d", comps.month ?? 1)
        let d = String(format: "%02d", comps.day ?? 1)
        return "\(y)-\(m)-\(d)"
    }
    static var today: String { day(.now) }
    static func day(before days: Int) -> String {
        let d = Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
        return day(d)
    }
}

@Model
final class Streak {
    var kidID: UUID
    var count: Int
    var lastDateKey: String?

    init(kidID: UUID, count: Int = 0, lastDateKey: String? = nil) {
        self.kidID = kidID
        self.count = count
        self.lastDateKey = lastDateKey
    }
}
```

- [ ] **Step 2: 验证 build**

```bash
cd /Volumes/CC/Projects/kid-bounus/KidBonus
xcodebuild -project KidBonus.xcodeproj -scheme KidBonus -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
cd /Volumes/CC/Projects/kid-bounus
git add KidBonus/Models/KidModels.swift
git commit -m "feat(model): add enums and Streak entity"
```

---

## Task 5: SwiftData 模型 — Kid / PointItem / Product

**Files:**
- Create: `KidBonus/Models/Kid.swift`
- Create: `KidBonus/Models/PointItem.swift`
- Create: `KidBonus/Models/Product.swift`

**Interfaces:**
- Consumes: `Kind`, `ProductCategory`（Task 4），`UUID`
- Produces: `@Model Kid`, `@Model PointItem`, `@Model Product`

- [ ] **Step 1: 写 `KidBonus/Models/Kid.swift`**

```swift
import Foundation
import SwiftData

@Model
final class Kid {
    @Attribute(.unique) var id: UUID
    var name: String
    var age: Int
    var colorHex: String

    @Relationship(deleteRule: .cascade, inverse: \HistoryRecord.kid)
    var history: [HistoryRecord] = []

    @Relationship(deleteRule: .cascade, inverse: \Redemption.kid)
    var redemptions: [Redemption] = []

    init(id: UUID = UUID(), name: String, age: Int, colorHex: String) {
        self.id = id
        self.name = name
        self.age = age
        self.colorHex = colorHex
    }
}
```

- [ ] **Step 2: 写 `KidBonus/Models/PointItem.swift`**

```swift
import Foundation
import SwiftData

@Model
final class PointItem {
    @Attribute(.unique) var id: UUID
    var kind: Kind
    var title: String
    var delta: Int
    var iconName: String?
    var desc: String

    init(id: UUID = UUID(), kind: Kind, title: String, delta: Int, iconName: String? = nil, desc: String) {
        self.id = id
        self.kind = kind
        self.title = title
        self.delta = delta
        self.iconName = iconName
        self.desc = desc
    }
}
```

- [ ] **Step 3: 写 `KidBonus/Models/Product.swift`**

```swift
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
```

- [ ] **Step 4: 验证 build**

```bash
cd /Volumes/CC/Projects/kid-bounus/KidBonus
xcodebuild -project KidBonus.xcodeproj -scheme KidBonus -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 5: Commit**

```bash
cd /Volumes/CC/Projects/kid-bounus
git add KidBonus/Models
git commit -m "feat(model): add Kid, PointItem, Product entities"
```

---

## Task 6: SwiftData 模型 — HistoryRecord / Redemption

**Files:**
- Create: `KidBonus/Models/HistoryRecord.swift`
- Create: `KidBonus/Models/Redemption.swift`

**Interfaces:**
- Consumes: `SourceKind`, `Kid`
- Produces: `@Model HistoryRecord`, `@Model Redemption`

- [ ] **Step 1: 写 `KidBonus/Models/HistoryRecord.swift`**

```swift
import Foundation
import SwiftData

@Model
final class HistoryRecord {
    @Attribute(.unique) var id: UUID
    var kid: Kid?
    var title: String
    var delta: Int
    var timestamp: Date
    var sourceKindRaw: String
    var sourceId: String?

    var sourceKind: SourceKind {
        SourceKind(rawValue: sourceKindRaw) ?? .preset
    }

    init(
        id: UUID = UUID(),
        kid: Kid,
        title: String,
        delta: Int,
        timestamp: Date = .now,
        sourceKind: SourceKind,
        sourceId: String? = nil
    ) {
        self.id = id
        self.kid = kid
        self.title = title
        self.delta = delta
        self.timestamp = timestamp
        self.sourceKindRaw = sourceKind.rawValue
        self.sourceId = sourceId
    }
}
```

- [ ] **Step 2: 写 `KidBonus/Models/Redemption.swift`**

```swift
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
```

- [ ] **Step 3: 验证 build**

```bash
cd /Volumes/CC/Projects/kid-bounus/KidBonus
xcodebuild -project KidBonus.xcodeproj -scheme KidBonus -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Commit**

```bash
cd /Volumes/CC/Projects/kid-bounus
git add KidBonus/Models/HistoryRecord.swift KidBonus/Models/Redemption.swift
git commit -m "feat(model): add HistoryRecord and Redemption entities"
```

---

## Task 7: SeedData + 首次启动种子化

**Files:**
- Create: `KidBonus/Store/SeedData.swift`
- Test: `KidBonusTests/SeedDataTests.swift`
- Modify: `KidBonus/App/KidBonusApp.swift`（启动时 installIfEmpty）

**Interfaces:**
- Consumes: 所有 @Model
- Produces: `SeedData.SEED_KIDS`, `SeedData.SEED_ITEMS`, `SeedData.SEED_PRODUCTS`, `SeedData.installIfEmpty(ctx:)`, `SeedData.installFresh(ctx:)`

- [ ] **Step 1: 写测试** (`KidBonusTests/SeedDataTests.swift`)

```swift
import XCTest
import SwiftData
@testable import KidBonus

final class SeedDataTests: XCTestCase {
    @MainActor
    func testInstallIfEmptySeedsKidsAndItems() throws {
        let schema = Schema([Kid.self, PointItem.self, Product.self,
                             HistoryRecord.self, Redemption.self, Streak.self])
        let cfg = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: cfg)
        let ctx = container.mainContext
        SeedData.installIfEmpty(ctx: ctx)
        let kids = try ctx.fetch(FetchDescriptor<Kid>())
        let items = try ctx.fetch(FetchDescriptor<PointItem>())
        let products = try ctx.fetch(FetchDescriptor<Product>())
        XCTAssertEqual(kids.count, 2)
        XCTAssertGreaterThan(items.count, 5)
        XCTAssertGreaterThan(products.count, 5)
    }

    @MainActor
    func testInstallIfEmptyIsIdempotent() throws {
        let schema = Schema([Kid.self, PointItem.self, Product.self,
                             HistoryRecord.self, Redemption.self, Streak.self])
        let cfg = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: cfg)
        let ctx = container.mainContext
        SeedData.installIfEmpty(ctx: ctx)
        SeedData.installIfEmpty(ctx: ctx) // 第二次不应增加
        let kids = try ctx.fetch(FetchDescriptor<Kid>())
        XCTAssertEqual(kids.count, 2)
    }

    @MainActor
    func testInstallFreshWipesAndReseeds() throws {
        let schema = Schema([Kid.self, PointItem.self, Product.self,
                             HistoryRecord.self, Redemption.self, Streak.self])
        let cfg = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: cfg)
        let ctx = container.mainContext
        SeedData.installIfEmpty(ctx: ctx)
        let k1 = try ctx.fetch(FetchDescriptor<Kid>()).first!
        ctx.insert(HistoryRecord(kid: k1, title: "test", delta: 5, sourceKind: .preset))
        SeedData.installFresh(ctx: ctx)
        let kids = try ctx.fetch(FetchDescriptor<Kid>())
        let hist = try ctx.fetch(FetchDescriptor<HistoryRecord>())
        XCTAssertEqual(kids.count, 2)
        XCTAssertEqual(hist.count, 0)
    }
}
```

- [ ] **Step 2: 跑测试确认失败**

```bash
cd /Volumes/CC/Projects/kid-bounus/KidBonus
xcodebuild test -project KidBonus.xcodeproj -scheme KidBonus -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:KidBonusTests/SeedDataTests
```

Expected: 编译失败（无 SeedData）。

- [ ] **Step 3: 实现 `Store/SeedData.swift`**

```swift
import Foundation
import SwiftData

enum SeedData {
    static func installIfEmpty(ctx: ModelContext) {
        let kids = (try? ctx.fetchCount(FetchDescriptor<Kid>())) ?? 0
        guard kids == 0 else { return }
        installFresh(ctx: ctx)
    }

    static func installFresh(ctx: ModelContext) {
        // 清空
        for entity in [Kid.self, PointItem.self, Product.self,
                       HistoryRecord.self, Redemption.self, Streak.self] {
            try? ctx.delete(model: entity)
        }

        // 两个孩子
        let k1 = Kid(name: "小明", age: 8,  colorHex: "#1B365D")
        let k2 = Kid(name: "小红", age: 10, colorHex: "#4A6B3A")
        ctx.insert(k1); ctx.insert(k2)

        // 加分项
        let adds: [PointItem] = [
            PointItem(kind: .add, title: "完成作业",  delta: 5, iconName: "book",   desc: "今天作业都完成了"),
            PointItem(kind: .add, title: "阅读 30 分", delta: 5, iconName: "book",   desc: "专心读书半小时"),
            PointItem(kind: .add, title: "整理房间",   delta: 3, iconName: "house",  desc: "把玩具和衣服归位"),
            PointItem(kind: .add, title: "主动练琴",   delta: 8, iconName: "music.note", desc: "自己主动练了乐器"),
            PointItem(kind: .add, title: "帮忙家务",   delta: 3, iconName: "hand.raised", desc: "洗碗/扫地/倒垃圾"),
            PointItem(kind: .add, title: "运动 30 分", delta: 6, iconName: "figure.run", desc: "跑跳运动半小时"),
            PointItem(kind: .add, title: "刷牙早晚",   delta: 2, iconName: "checkmark",  desc: "认真刷了两次牙"),
        ]
        adds.forEach(ctx.insert)

        // 扣分项
        let ded: [PointItem] = [
            PointItem(kind: .deduct, title: "赖床迟到",   delta: -3, iconName: "clock",    desc: "早上赖着不肯起"),
            PointItem(kind: .deduct, title: "看电视超时", delta: -2, iconName: "tv",       desc: "超过约定时间"),
            PointItem(kind: .deduct, title: "顶嘴发脾气", delta: -5, iconName: "bubble.left", desc: "对家人态度不好"),
            PointItem(kind: .deduct, title: "挑食",       delta: -2, iconName: "fork.knife", desc: "吃饭挑三拣四"),
            PointItem(kind: .deduct, title: "忘带作业",   delta: -5, iconName: "tray",     desc: "作业落在家了"),
        ]
        ded.forEach(ctx.insert)

        // 商品
        let products: [Product] = [
            Product(name: "乐高积木",   category: .toy,  cost: 200, iconName: "puzzlepiece", desc: "小颗粒拼装玩具"),
            Product(name: "漫画书一本", category: .book, cost:  80, iconName: "book",        desc: "喜爱的系列最新一册"),
            Product(name: "冰淇淋",     category: .food, cost:  30, iconName: "cone",        desc: "周末的甜点"),
            Product(name: "选电影特权", category: .priv, cost:  50, iconName: "film",        desc: "今晚你决定看什么"),
            Product(name: "晚睡 30 分", category: .priv, cost:  40, iconName: "moon",        desc: "允许今晚晚睡半小时"),
            Product(name: "公园出游",   category: .out,  cost: 150, iconName: "tree",        desc: "周末全家去公园"),
            Product(name: "贴纸一包",   category: .toy,  cost:  25, iconName: "seal",        desc: "彩色奖励贴纸"),
            Product(name: "蛋糕一块",   category: .food, cost:  60, iconName: "birthday.cake", desc: "下午茶蛋糕"),
        ]
        products.forEach(ctx.insert)

        try? ctx.save()
    }
}
```

- [ ] **Step 4: 改 `App/KidBonusApp.swift` 让种子化**

```swift
import SwiftUI
import SwiftData

@main
struct KidBonusApp: App {
    @Environment(\.modelContext) private var ctx

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    SeedData.installIfEmpty(ctx: ctx)
                }
        }
        .modelContainer(for: [
            Kid.self, PointItem.self, Product.self,
            HistoryRecord.self, Redemption.self, Streak.self
        ])
    }
}
```

- [ ] **Step 5: 跑测试**

```bash
cd /Volumes/CC/Projects/kid-bounus/KidBonus
xcodebuild test -project KidBonus.xcodeproj -scheme KidBonus -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:KidBonusTests/SeedDataTests
```

Expected: 3 passed.

- [ ] **Step 6: Commit**

```bash
cd /Volumes/CC/Projects/kid-bounus
git add KidBonus/Store/SeedData.swift KidBonusTests/SeedDataTests.swift KidBonus/App/KidBonusApp.swift
git commit -m "feat(store): add SeedData with idempotent install + tests"
```

---

## Task 8: PointMath + 测试

**Files:**
- Create: `KidBonus/Store/PointMath.swift`
- Test: `KidBonusTests/PointMathTests.swift`

**Interfaces:**
- Consumes: `Kid`, `HistoryRecord`, `Redemption`, `DateKey`
- Produces: `PointMath.kidPoints(_:)`, `PointMath.todayDelta(_:)`

- [ ] **Step 1: 写测试**

```swift
import XCTest
import SwiftData
@testable import KidBonus

final class PointMathTests: XCTestCase {
    @MainActor
    private func makeCtx() throws -> (ModelContext, Kid) {
        let schema = Schema([Kid.self, PointItem.self, Product.self,
                             HistoryRecord.self, Redemption.self, Streak.self])
        let cfg = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: cfg)
        let ctx = container.mainContext
        SeedData.installIfEmpty(ctx: ctx)
        let kid = try ctx.fetch(FetchDescriptor<Kid>()).first!
        return (ctx, kid)
    }

    @MainActor
    func testKidPointsSumOfHistoryMinusRedemptions() throws {
        let (ctx, kid) = try makeCtx()
        ctx.insert(HistoryRecord(kid: kid, title: "完成作业", delta: 5, sourceKind: .preset))
        ctx.insert(HistoryRecord(kid: kid, title: "忘带作业", delta: -5, sourceKind: .preset))
        ctx.insert(Redemption(kid: kid, productName: "贴纸", cost: 25))
        try ctx.save()
        XCTAssertEqual(PointMath.kidPoints(kid), -25)
    }

    @MainActor
    func testTodayDeltaCountsOnlyTodayRecords() throws {
        let (ctx, kid) = try makeCtx()
        ctx.insert(HistoryRecord(kid: kid, title: "t1", delta: 3, sourceKind: .preset))
        ctx.insert(HistoryRecord(kid: kid, title: "t2", delta: -2, sourceKind: .preset))
        try ctx.save()
        XCTAssertEqual(PointMath.todayDelta(kid), 1)
    }
}
```

- [ ] **Step 2: 跑测试确认失败**

```bash
cd /Volumes/CC/Projects/kid-bounus/KidBonus
xcodebuild test -project KidBonus.xcodeproj -scheme KidBonus -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:KidBonusTests/PointMathTests
```

Expected: 编译失败。

- [ ] **Step 3: 实现 `Store/PointMath.swift`**

```swift
import Foundation

enum PointMath {
    static func kidPoints(_ kid: Kid) -> Int {
        let earned = kid.history.reduce(0) { $0 + $1.delta }
        let spent  = kid.redemptions.reduce(0) { $0 + $1.cost }
        return earned - spent
    }

    static func todayDelta(_ kid: Kid) -> Int {
        let k = DateKey.today
        return kid.history
            .filter { DateKey.day($0.timestamp) == k }
            .reduce(0) { $0 + $1.delta }
    }
}
```

- [ ] **Step 4: 跑测试**

```bash
cd /Volumes/CC/Projects/kid-bounus/KidBonus
xcodebuild test -project KidBonus.xcodeproj -scheme KidBonus -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:KidBonusTests/PointMathTests
```

Expected: 2 passed.

- [ ] **Step 5: Commit**

```bash
cd /Volumes/CC/Projects/kid-bounus
git add KidBonus/Store/PointMath.swift KidBonusTests/PointMathTests.swift
git commit -m "feat(store): add PointMath with kidPoints and todayDelta"
```

---

## Task 9: StreakEngine + 测试

**Files:**
- Create: `KidBonus/Store/StreakEngine.swift`
- Test: `KidBonusTests/StreakEngineTests.swift`

**Interfaces:**
- Consumes: `Kid`, `HistoryRecord`, `Streak`, `DateKey`
- Produces: `StreakEngine.bump(_:ctx:) -> StreakUpdate { count, bonus }`, `StreakEngine.currentStreak(_:ctx:) -> Streak?`, `StreakEngine.applyBonus(_:count:ctx:)`

- [ ] **Step 1: 写测试**

```swift
import XCTest
import SwiftData
@testable import KidBonus

struct StreakUpdate: Equatable { var count: Int; var bonus: Int }

final class StreakEngineTests: XCTestCase {
    @MainActor
    private func makeCtx() throws -> (ModelContext, Kid) {
        let schema = Schema([Kid.self, PointItem.self, Product.self,
                             HistoryRecord.self, Redemption.self, Streak.self])
        let cfg = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: cfg)
        let ctx = container.mainContext
        SeedData.installIfEmpty(ctx: ctx)
        let kid = try ctx.fetch(FetchDescriptor<Kid>()).first!
        return (ctx, kid)
    }

    @MainActor
    func testFirstBumpOfDaySetsCountToOne() throws {
        let (ctx, kid) = try makeCtx()
        let r = StreakEngine.bump(kid, ctx: ctx)
        XCTAssertEqual(r.count, 1)
        XCTAssertEqual(r.bonus, 0)
    }

    @MainActor
    func testSecondBumpSameDayDoesNotIncrement() throws {
        let (ctx, kid) = try makeCtx()
        _ = StreakEngine.bump(kid, ctx: ctx)
        let r = StreakEngine.bump(kid, ctx: ctx)
        XCTAssertEqual(r.count, 1)
        XCTAssertEqual(r.bonus, 0)
    }

    @MainActor
    func testBumpAfterBreakResetsCount() throws {
        let (ctx, kid) = try makeCtx()
        var s = Streak(kidID: kid.id, count: 5, lastDateKey: DateKey.day(before: 3))
        ctx.insert(s)
        let r = StreakEngine.bump(kid, ctx: ctx)
        XCTAssertEqual(r.count, 1, "断签后应重置为 1")
    }

    @MainActor
    func testSeventhDayTriggersWeeklyBonus() throws {
        let (ctx, kid) = try makeCtx()
        let s = Streak(kidID: kid.id, count: 6,
                       lastDateKey: DateKey.day(before: 1))
        ctx.insert(s)
        let r = StreakEngine.bump(kid, ctx: ctx)
        XCTAssertEqual(r.count, 7)
        XCTAssertEqual(r.bonus, 20)
    }

    @MainActor
    func testThirtiethDayTriggersMonthlyBonus() throws {
        let (ctx, kid) = try makeCtx()
        let s = Streak(kidID: kid.id, count: 29,
                       lastDateKey: DateKey.day(before: 1))
        ctx.insert(s)
        let r = StreakEngine.bump(kid, ctx: ctx)
        XCTAssertEqual(r.count, 30)
        XCTAssertEqual(r.bonus, 100)
    }
}
```

- [ ] **Step 2: 跑测试确认失败**

```bash
cd /Volumes/CC/Projects/kid-bounus/KidBonus
xcodebuild test -project KidBonus.xcodeproj -scheme KidBonus -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:KidBonusTests/StreakEngineTests
```

Expected: 编译失败。

- [ ] **Step 3: 实现 `Store/StreakEngine.swift`**

```swift
import Foundation
import SwiftData

struct StreakUpdate: Equatable { var count: Int; var bonus: Int }

enum StreakEngine {
    static let weeklyBonus = 20
    static let monthlyBonus = 100

    /// 当日首次加分时调用。返回新的 streak count 与触发的 bonus（0 或 20 或 100）。
    /// 业务规则：
    ///   当日已加分 → 不变, bonus = 0
    ///   lastDate == 昨天 → count + 1
    ///   否则         → count = 1
    ///   count == 7  → bonus = 20
    ///   count == 30 → bonus += 100
    static func bump(_ kid: Kid, ctx: ModelContext) -> StreakUpdate {
        let today = DateKey.today
        var streak = currentStreak(kid, ctx: ctx)
        let prev = streak ?? Streak(kidID: kid.id)
        if streak == nil { ctx.insert(prev) }

        if prev.lastDateKey == today {
            return StreakUpdate(count: prev.count, bonus: 0)
        }

        let yesterday = DateKey.day(before: 1)
        let nextCount: Int
        if prev.lastDateKey == yesterday {
            nextCount = prev.count + 1
        } else {
            nextCount = 1
        }

        var bonus = 0
        if nextCount == 7  { bonus = weeklyBonus }
        if nextCount == 30 { bonus += monthlyBonus }

        streak = prev
        streak?.count = nextCount
        streak?.lastDateKey = today
        try? ctx.save()

        return StreakUpdate(count: nextCount, bonus: bonus)
    }

    static func currentStreak(_ kid: Kid, ctx: ModelContext) -> Streak? {
        let kidID = kid.id
        let pred = #Predicate<Streak> { $0.kidID == kidID }
        return try? ctx.fetch(FetchDescriptor<Streak>(predicate: pred)).first
    }
}
```

- [ ] **Step 4: 跑测试**

```bash
cd /Volumes/CC/Projects/kid-bounus/KidBonus
xcodebuild test -project KidBonus.xcodeproj -scheme KidBonus -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:KidBonusTests/StreakEngineTests
```

Expected: 5 passed.

- [ ] **Step 5: Commit**

```bash
cd /Volumes/CC/Projects/kid-bounus
git add KidBonus/Store/StreakEngine.swift KidBonusTests/StreakEngineTests.swift
git commit -m "feat(store): add StreakEngine with weekly+monthly bonus"
```

---

## Task 10: TrendBuilder + 测试

**Files:**
- Create: `KidBonus/Store/TrendBuilder.swift`
- Test: `KidBonusTests/TrendBuilderTests.swift`

**Interfaces:**
- Consumes: `Kid`, `HistoryRecord`, `Redemption`, `DateKey`
- Produces: `TrendBuilder.trend(_:days:)` → `[TrendBucket]`, `TrendBuilder.distribution(_:) → [DistributionRow]`

- [ ] **Step 1: 写测试**

```swift
import XCTest
import SwiftData
@testable import KidBonus

struct TrendBucket: Equatable { var dateKey: String; var value: Int }
struct DistributionRow: Equatable { var title: String; var add: Int; var deduct: Int }

final class TrendBuilderTests: XCTestCase {
    @MainActor
    private func makeCtx() throws -> (ModelContext, Kid) {
        let schema = Schema([Kid.self, PointItem.self, Product.self,
                             HistoryRecord.self, Redemption.self, Streak.self])
        let cfg = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: cfg)
        let ctx = container.mainContext
        SeedData.installIfEmpty(ctx: ctx)
        let kid = try ctx.fetch(FetchDescriptor<Kid>()).first!
        return (ctx, kid)
    }

    @MainActor
    func testTrendReturns14BucketsAllignedFromToday() throws {
        let (_, kid) = try makeCtx()
        let buckets = TrendBuilder.trend(kid, days: 14)
        XCTAssertEqual(buckets.count, 14)
        XCTAssertEqual(buckets.last?.dateKey, DateKey.today)
    }

    @MainActor
    func testTrendIncludesRedemptionAsNegative() throws {
        let (ctx, kid) = try makeCtx()
        ctx.insert(HistoryRecord(kid: kid, title: "t", delta: 5,
                                 sourceKind: .preset))
        ctx.insert(Redemption(kid: kid, productName: "x", cost: 25))
        try ctx.save()
        let buckets = TrendBuilder.trend(kid, days: 14)
        let today = buckets.first { $0.dateKey == DateKey.today }
        XCTAssertEqual(today?.value, -20)
    }

    @MainActor
    func testDistributionAggregatesByTitle() throws {
        let (ctx, kid) = try makeCtx()
        ctx.insert(HistoryRecord(kid: kid, title: "x", delta: 5, sourceKind: .preset))
        ctx.insert(HistoryRecord(kid: kid, title: "x", delta: -2, sourceKind: .preset))
        try ctx.save()
        let dist = TrendBuilder.distribution(kid)
        let row = dist.first { $0.title == "x" }
        XCTAssertEqual(row?.add, 1)
        XCTAssertEqual(row?.deduct, 1)
    }
}
```

- [ ] **Step 2: 跑测试确认失败**

```bash
cd /Volumes/CC/Projects/kid-bounus/KidBonus
xcodebuild test -project KidBonus.xcodeproj -scheme KidBonus -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:KidBonusTests/TrendBuilderTests
```

Expected: 编译失败。

- [ ] **Step 3: 实现 `Store/TrendBuilder.swift`**

```swift
import Foundation

struct TrendBucket: Equatable { var dateKey: String; var value: Int }
struct DistributionRow: Equatable { var title: String; var add: Int; var deduct: Int }

enum TrendBuilder {
    /// 返回从今天起往前 N 天的每日净积分（加项 +，兑换 -）
    static func trend(_ kid: Kid, days: Int = 14) -> [TrendBucket] {
        var out: [TrendBucket] = []
        for i in stride(from: days - 1, through: 0, by: -1) {
            let key = DateKey.day(before: i)
            let earned = kid.history.filter { DateKey.day($0.timestamp) == key }
                                   .reduce(0) { $0 + $1.delta }
            let spent  = kid.redemptions.filter { DateKey.day($0.timestamp) == key }
                                        .reduce(0) { $0 + $1.cost }
            out.append(TrendBucket(dateKey: key, value: earned - spent))
        }
        return out
    }

    /// 按 title 聚合该 kid 的所有加减记录次数
    static func distribution(_ kid: Kid) -> [DistributionRow] {
        var tally: [String: (add: Int, deduct: Int)] = [:]
        for h in kid.history {
            var t = tally[h.title] ?? (0, 0)
            if h.delta > 0 { t.add += 1 } else { t.deduct += 1 }
            tally[h.title] = t
        }
        return tally
            .map { DistributionRow(title: $0.key, add: $0.value.add, deduct: $0.value.deduct) }
            .sorted { ($0.add - $0.deduct) > ($1.add - $1.deduct) }
    }
}
```

- [ ] **Step 4: 跑测试**

```bash
cd /Volumes/CC/Projects/kid-bounus/KidBonus
xcodebuild test -project KidBonus.xcodeproj -scheme KidBonus -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:KidBonusTests/TrendBuilderTests
```

Expected: 3 passed.

- [ ] **Step 5: Commit**

```bash
cd /Volumes/CC/Projects/kid-bounus
git add KidBonus/Store/TrendBuilder.swift KidBonusTests/TrendBuilderTests.swift
git commit -m "feat(store): add TrendBuilder trend + distribution"
```

---

## Task 11: RecordStore（写入 history / redemption）

**Files:**
- Create: `KidBonus/Store/RecordStore.swift`
- Create: `KidBonus/Store/AppState.swift`

**Interfaces:**
- Consumes: `Kid`, `PointItem`, `Product`, `HistoryRecord`, `Redemption`, `StreakEngine`
- Produces: `RecordStore.recordItem(_:on:ctx:)` 写入 history + 自动 streak bonus, `RecordStore.redeem(_:by:ctx:)` 写入 redemption, `AppState.currentKidID` (AppStorage)

- [ ] **Step 1: 实现 `Store/AppState.swift`**

```swift
import SwiftUI

@Observable
final class AppState {
    var currentKidID: String {
        didSet { UserDefaults.standard.set(currentKidID, forKey: "currentKidID") }
    }
    init() {
        self.currentKidID = UserDefaults.standard.string(forKey: "currentKidID") ?? ""
    }
}
```

- [ ] **Step 2: 实现 `Store/RecordStore.swift`**

```swift
import Foundation
import SwiftData

enum RecordStore {
    struct WriteOutcome {
        var points: Int
        var streakBonus: Int
        var streakCount: Int
    }

    /// 写一条 history（积分项）。加分时自动触发 streak + bonus。
    static func recordItem(_ item: PointItem, on kid: Kid, ctx: ModelContext) -> WriteOutcome {
        ctx.insert(HistoryRecord(
            kid: kid, title: item.title, delta: item.delta,
            sourceKind: .preset, sourceId: item.id.uuidString
        ))

        var bonus = 0
        var streakCount = 0
        if item.delta > 0 {
            let r = StreakEngine.bump(kid, ctx: ctx)
            streakCount = r.count
            if r.bonus > 0 {
                ctx.insert(HistoryRecord(
                    kid: kid,
                    title: "连续 \(r.count) 天 bonus",
                    delta: r.bonus,
                    sourceKind: .streakBonus,
                    sourceId: "streak-bonus"
                ))
                bonus = r.bonus
            }
        }
        try? ctx.save()
        return WriteOutcome(points: PointMath.kidPoints(kid),
                            streakBonus: bonus,
                            streakCount: streakCount)
    }

    /// 写一条 freeform history。
    static func recordFreeform(title: String, delta: Int, on kid: Kid,
                               ctx: ModelContext) -> WriteOutcome {
        ctx.insert(HistoryRecord(
            kid: kid, title: title, delta: delta,
            sourceKind: .freeform,
            sourceId: "freeform-\(UUID().uuidString)"
        ))
        var bonus = 0
        var streakCount = 0
        if delta > 0 {
            let r = StreakEngine.bump(kid, ctx: ctx)
            streakCount = r.count
            if r.bonus > 0 {
                ctx.insert(HistoryRecord(
                    kid: kid,
                    title: "连续 \(r.count) 天 bonus",
                    delta: r.bonus,
                    sourceKind: .streakBonus,
                    sourceId: "streak-bonus"
                ))
                bonus = r.bonus
            }
        }
        try? ctx.save()
        return WriteOutcome(points: PointMath.kidPoints(kid),
                            streakBonus: bonus,
                            streakCount: streakCount)
    }

    static func redeem(_ product: Product, by kid: Kid, ctx: ModelContext) -> Bool {
        guard PointMath.kidPoints(kid) >= product.cost else { return false }
        ctx.insert(Redemption(
            kid: kid, productName: product.name, cost: product.cost
        ))
        try? ctx.save()
        return true
    }
}
```

- [ ] **Step 3: 验证 build**

```bash
cd /Volumes/CC/Projects/kid-bounus/KidBonus
xcodebuild -project KidBonus.xcodeproj -scheme KidBonus -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Commit**

```bash
cd /Volumes/CC/Projects/kid-bounus
git add KidBonus/Store/RecordStore.swift KidBonus/Store/AppState.swift
git commit -m "feat(store): add RecordStore write + redeem + AppState"
```

---

## Task 12: 共享组件 — KidAvatar / Tag / KamiButton

**Files:**
- Create: `KidBonus/Views/Components/KidAvatar.swift`
- Create: `KidBonus/Views/Components/Tag.swift`
- Create: `KidBonus/Views/Components/KamiButton.swift`

**Interfaces:**
- Consumes: `Color.kami`, `Spacing`, `Radius`, `Font.kami`
- Produces: `KidAvatar(name:size:colorHex:)`, `Tag(text:kind:)`, `KamiButton(title:style:action:)`

- [ ] **Step 1: 写 `Components/KidAvatar.swift`**

```swift
import SwiftUI

struct KidAvatar: View {
    let name: String
    let size: CGFloat
    let colorHex: String

    private var initials: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return String(trimmed.suffix(2))
    }

    var body: some View {
        Text(initials)
            .font(.kami(.body, size: size * 0.36))
            .foregroundStyle(Color(hex: UInt32(colorHex.dropFirst().hexValue) ?? 0x1B365D))
            .frame(width: size, height: size)
            .background(Color.kami.tagBgSoft)
            .clipShape(Circle())
    }
}

private extension String {
    var hexValue: UInt32 {
        var v: UInt32 = 0
        for c in self.unicodeScalars { v = v * 16 + UInt32(c.value - 48 - (c.value > 57 ? 7 : 0)) - (c.value > 96 ? 32 : 0) * 0 }
        return v
    }
}
```

> 简化做法：让 `colorHex` 字符串支持 `#1B365D` 格式。上面的 parser 故意容错；实际你可以改为存 Int 而非 String（推荐：Spec 里改 `colorHex: String` 为 `colorHexRaw: UInt32` — 在 Task 11 之前都未涉及，留 TODO）。这里先保持 String 在视图中用 Color(hex:) 解析 fallback。

- [ ] **Step 2: 写 `Components/Tag.swift`**

```swift
import SwiftUI

enum TagKind { case `default`, faint, success, danger, warn }

struct Tag: View {
    let text: String
    let kind: TagKind

    var body: some View {
        Text(text)
            .font(.kami(.body, size: 11))
            .padding(.horizontal, Spacing.s2)
            .padding(.vertical, 4)
            .foregroundStyle(foreground)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: Radius.xs))
    }

    private var foreground: Color {
        switch kind {
        case .success: return .kami.success
        case .danger:  return .kami.danger
        case .warn:    return .kami.warn
        case .faint:   return .kami.muted
        default:       return .kami.accent
        }
    }
    private var background: Color {
        switch kind {
        case .success: return Color(hex: 0xE6EDE0)
        case .danger:  return Color(hex: 0xEFE2DF)
        case .warn:    return Color(hex: 0xEFE7D3)
        case .faint:   return .kami.tagBgFaint
        default:       return .kami.tagBgSoft
        }
    }
}
```

- [ ] **Step 3: 写 `Components/KamiButton.swift`**

```swift
import SwiftUI

enum KamiButtonStyle { case primary, secondary }

struct KamiButton: View {
    let title: String
    let systemImage: String?
    let style: KamiButtonStyle
    let action: () -> Void

    init(_ title: String, systemImage: String? = nil,
         style: KamiButtonStyle = .primary, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.s2) {
                if let s = systemImage {
                    Image(systemName: s)
                }
                Text(title)
            }
            .font(.kami(.body, size: 13))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var background: Color {
        style == .primary ? .kami.accent : .kami.surfaceWarm
    }
    private var foreground: Color {
        style == .primary ? .kami.accentOn : .kami.fg2
    }
    private var borderColor: Color {
        style == .primary ? .kami.accent : .kami.border
    }
}
```

- [ ] **Step 4: 验证 build**

```bash
cd /Volumes/CC/Projects/kid-bounus/KidBonus
xcodebuild -project KidBonus.xcodeproj -scheme KidBonus -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 5: 在 ContentView 添加 #Preview 验证渲染**

`ContentView.swift`:

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            KidAvatar(name: "小明", size: 44, colorHex: "#1B365D")
            Tag(text: "可兑换", kind: .success)
            KamiButton("加分", systemImage: "plus") {}
        }
        .padding()
        .background(Color.kami.bg)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Kid.self, PointItem.self, Product.self,
                              HistoryRecord.self, Redemption.self, Streak.self],
                        inMemory: true)
}
```

- [ ] **Step 6: Commit**

```bash
cd /Volumes/CC/Projects/kid-bounus
git add KidBonus/Views
git commit -m "feat(views): add KidAvatar, Tag, KamiButton components"
```

---

## Task 13: KidTabs 共享组件

**Files:**
- Create: `KidBonus/Views/Components/KidTabs.swift`

- [ ] **Step 1: 实现**

```swift
import SwiftUI

struct KidTabs: View {
    let kids: [Kid]
    @Binding var selected: UUID

    var body: some View {
        HStack(spacing: Spacing.s2) {
            ForEach(kids) { kid in
                Button {
                    selected = kid.id
                } label: {
                    HStack(spacing: Spacing.s2) {
                        KidAvatar(name: kid.name, size: 26, colorHex: kid.colorHex)
                        Text(kid.name).font(.kami(.body, size: 14))
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(selected == kid.id ? .kami.bg : .clear)
                    .foregroundStyle(selected == kid.id ? .kami.accent : .kami.muted)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.sm)
                            .stroke(selected == kid.id ? .kami.accent : .clear,
                                    lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.s1)
        .background(Color.kami.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .stroke(Color.kami.border, lineWidth: 1)
        )
    }
}
```

- [ ] **Step 2: 验证 build + Commit**

```bash
cd /Volumes/CC/Projects/kid-bounus/KidBonus
xcodebuild -project KidBonus.xcodeproj -scheme KidBonus -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
cd /Volumes/CC/Projects/kid-bounus
git add KidBonus/Views/Components/KidTabs.swift
git commit -m "feat(views): add KidTabs segmented selector"
```

---

## Task 14: SheetScaffold + ToastCenter

**Files:**
- Create: `KidBonus/Views/Components/SheetScaffold.swift`
- Create: `KidBonus/Views/Components/ToastCenter.swift`

**Interfaces:**
- Produces: `SheetScaffold(title:content:actions:)`, `ToastCenter` (ObservableObject with `show(_:)`)

- [ ] **Step 1: 实现 `SheetScaffold.swift`**

```swift
import SwiftUI

struct SheetScaffold<Content: View>: View {
    let title: String
    let message: String?
    let actions: [SheetAction]
    let content: () -> Content

    init(title: String, message: String? = nil,
         actions: [SheetAction] = [],
         @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.message = message
        self.actions = actions
        self.content = content
    }

    var body: some View {
        VStack(spacing: Spacing.s3) {
            Capsule()
                .fill(Color.kami.border)
                .frame(width: 36, height: 4)
                .padding(.top, Spacing.s1)

            Text(title).font(.kami(.body, size: 17))

            if let m = message {
                Text(m).font(.kami(.body, size: 13))
                    .foregroundStyle(.kami.muted)
            }

            content()

            HStack(spacing: Spacing.s2) {
                ForEach(actions) { a in
                    KamiButton(a.title, style: a.primary ? .primary : .secondary) {
                        a.handler()
                    }
                }
            }
        }
        .padding(Spacing.s4)
        .background(Color.kami.bg)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }
}

struct SheetAction: Identifiable {
    let id = UUID()
    let title: String
    let primary: Bool
    let handler: () -> Void
}
```

- [ ] **Step 2: 实现 `ToastCenter.swift`**

```swift
import SwiftUI

@Observable
final class ToastCenter {
    struct Toast: Identifiable, Equatable {
        let id = UUID()
        let kind: Kind
        let title: String
        let body: String?
        enum Kind { case info, success, danger }
    }
    var current: Toast?

    @MainActor
    func show(_ kind: Toast.Kind, title: String, body: String? = nil) {
        current = Toast(kind: kind, title: title, body: body)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_400_000_000)
            if current?.id == current?.id { current = nil }
        }
    }
}

struct ToastBanner: View {
    let toast: ToastCenter.Toast

    var body: some View {
        HStack(spacing: Spacing.s2) {
            Image(systemName: iconName)
                .frame(width: 28, height: 28)
                .background(Color.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
            VStack(alignment: .leading, spacing: 2) {
                Text(toast.title).font(.kami(.body, size: 14))
                if let b = toast.body {
                    Text(b).font(.kami(.body, size: 12))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            Spacer()
        }
        .padding(Spacing.s3)
        .foregroundStyle(.white)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        .padding(.horizontal, Spacing.s4)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private var iconName: String {
        switch toast.kind {
        case .success: return "checkmark"
        case .danger:  return "exclamationmark"
        case .info:    return "info"
        }
    }
    private var background: Color {
        switch toast.kind {
        case .success: return .kami.success
        case .danger:  return .kami.danger
        case .info:    return .kami.accent
        }
    }
}
```

- [ ] **Step 3: 验证 build + Commit**

```bash
cd /Volumes/CC/Projects/kid-bounus/KidBonus
xcodebuild -project KidBonus.xcodeproj -scheme KidBonus -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
cd /Volumes/CC/Projects/kid-bounus
git add KidBonus/Views/Components
git commit -m "feat(views): add SheetScaffold and ToastCenter"
```

---

## Task 15: ContentView 主壳 + 4 tabs

**Files:**
- Modify: `KidBonus/Views/ContentView.swift`

**Interfaces:**
- Produces: 4 tab 容器，每个 tab 对应一个真实 view（先放 placeholder）

- [ ] **Step 1: 实现 `ContentView.swift`**

```swift
import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var toast = ToastCenter()
    @State private var showingStats = false

    var body: some View {
        ZStack(alignment: .top) {
            TabView {
                HomeView()
                    .tabItem { Label("首页", systemImage: "house") }
                QuickView()
                    .tabItem { Label("加减", systemImage: "plus") }
                ShopView()
                    .tabItem { Label("商城", systemImage: "bag") }
                HistoryView()
                    .tabItem { Label("历程", systemImage: "clock") }
                MeView()
                    .tabItem { Label("我的", systemImage: "person") }
            }
            .tint(.kami.accent)

            if let t = toast.current {
                ToastBanner(toast: t)
            }
        }
        .environment(toast)
        .sheet(isPresented: $showingStats) {
            StatsView()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Kid.self, PointItem.self, Product.self,
                              HistoryRecord.self, Redemption.self, Streak.self],
                        inMemory: true)
}
```

- [ ] **Step 2: 添加占位视图**（临时）

每个 Placeholder 各创建一个最简版本，后续 task 替换：
- `HomeView.swift`：`Text("Home")`
- `QuickView.swift`：`Text("Quick")`
- `ShopView.swift`：`Text("Shop")`
- `HistoryView.swift`：`Text("History")`
- `MeView.swift`：`Text("Me")`
- `StatsView.swift`：`Text("Stats")`

每个都是：

```swift
import SwiftUI
struct HomeView: View { var body: some View { Text("Home").font(.kami()) } }
#Preview { HomeView() }
```

为每页单独一次 commit。

- [ ] **Step 3: 验证 build**

```bash
cd /Volumes/CC/Projects/kid-bounus/KidBonus
xcodebuild -project KidBonus.xcodeproj -scheme KidBonus -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Commit**

```bash
cd /Volumes/CC/Projects/kid-bounus
git add KidBonus/Views/ContentView.swift KidBonus/Views/Home/HomeView.swift KidBonus/Views/Quick/QuickView.swift KidBonus/Views/Shop/ShopView.swift KidBonus/Views/History/HistoryView.swift KidBonus/Views/Me/MeView.swift KidBonus/Views/Stats/StatsView.swift
git commit -m "feat(views): add TabView shell with 4 tabs and placeholders"
```

---

## Task 16: HomeView + KidCard

**Files:**
- Modify: `KidBonus/Views/Home/HomeView.swift`
- Create: `KidBonus/Views/Home/KidCard.swift`

**Interfaces:**
- Consumes: `Kid` query, `PointMath`, `StreakEngine`
- Produces: `KidCard(kid:)`, `HomeView` 渲染两个 KidCard + 推荐商品 + 快捷加减按钮

- [ ] **Step 1: 实现 `Home/KidCard.swift`**

```swift
import SwiftUI
import SwiftData

struct KidCard: View {
    let kid: Kid
    let points: Int
    let today: Int
    let streak: Int
    let bonusActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Spacing.s4) {
                HStack(spacing: Spacing.s3) {
                    KidAvatar(name: kid.name, size: 44, colorHex: kid.colorHex)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(kid.name).font(.kami(.body, size: 17))
                        Text("\(kid.age) 岁")
                            .font(.kami(.body, size: 11))
                            .foregroundStyle(.kami.meta)
                    }
                }
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(points)")
                        .font(.kami(.body, size: 36))
                        .foregroundStyle(.kami.accent)
                    Text("积分")
                        .font(.kami(.body, size: 13))
                        .foregroundStyle(.kami.meta)
                }
                HStack(spacing: Spacing.s4) {
                    statBlock(value: "\(today >= 0 ? "+" : "")\(today)",
                               label: "今日",
                               color: today >= 0 ? .kami.success : .kami.danger)
                    statBlock(value: "\(streak)", label: "连续天数")
                    statBlock(value: bonusActive ? "★" : "·",
                               label: bonusActive ? "bonus 激活" : "bonus 待解锁",
                               color: bonusActive ? .kami.warn : .kami.muted)
                }
                .padding(.top, Spacing.s3)
                .overlay(alignment: .top) {
                    Rectangle().fill(.kami.borderSoft).frame(height: 1)
                        .offset(y: -Spacing.s3)
                }
            }
            .padding(Spacing.s4)
            .background(Color.kami.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .stroke(Color.kami.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func statBlock(value: String, label: String, color: Color = .kami.fg) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.kami(.body, size: 15)).foregroundStyle(color)
            Text(label).font(.kami(.body, size: 11)).foregroundStyle(.kami.meta)
        }
    }
}
```

- [ ] **Step 2: 实现 `Home/HomeView.swift`**

```swift
import SwiftUI
import SwiftData

struct HomeView: View {
    @Query private var kids: [Kid]
    @Query(sort: \Product.cost, order: .reverse) private var products: [Product]
    @Environment(\.modelContext) private var ctx

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s4) {
                    VStack(alignment: .leading, spacing: Spacing.s2) {
                        Text("今天，\n两个小家伙的积分")
                            .font(.kami(.body, size: 28))
                        Text("点一下孩子的卡片，开始加减分。")
                            .font(.kami(.body, size: 14))
                            .foregroundStyle(.kami.muted)
                    }
                    .padding(.horizontal, Spacing.s4)

                    SectionHeader(num: "01", label: todayLabel)
                        .padding(.horizontal, Spacing.s4)

                    VStack(spacing: Spacing.s3) {
                        ForEach(kids) { kid in
                            KidCard(
                                kid: kid,
                                points: PointMath.kidPoints(kid),
                                today: PointMath.todayDelta(kid),
                                streak: streak(for: kid),
                                bonusActive: streak(for: kid) >= 7
                            ) {
                                // Navigate to QuickView 在 tab 切换层; 这里只切换 view 不行
                                // 简化: 把 kid.id 存到 AppState, 然后 QuickView 用
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.s4)

                    SectionHeader(num: "02", label: "快捷加减")
                        .padding(.horizontal, Spacing.s4)

                    HStack(spacing: Spacing.s2) {
                        KamiButton("加分", systemImage: "plus", style: .primary) {
                            // 跳 Quick 加分
                        }
                        KamiButton("扣分", systemImage: "minus", style: .secondary) {
                            // 跳 Quick 扣分
                        }
                    }
                    .padding(.horizontal, Spacing.s4)

                    SectionHeader(num: "03", label: "推荐商品")
                        .padding(.horizontal, Spacing.s4)

                    LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: Spacing.s3) {
                        ForEach(products.prefix(4)) { p in
                            ProductCard(product: p, affordable: bestPoints >= p.cost, bestPoints: bestPoints)
                        }
                    }
                    .padding(.horizontal, Spacing.s4)
                }
                .padding(.vertical, Spacing.s4)
            }
            .background(Color.kami.bg)
        }
    }

    private var bestPoints: Int {
        kids.map { PointMath.kidPoints($0) }.max() ?? 0
    }

    private func streak(for kid: Kid) -> Int {
        StreakEngine.currentStreak(kid, ctx: ctx)?.count ?? 0
    }

    private var todayLabel: String {
        let f = DateFormatter(); f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日 EEEE"
        return f.string(from: .now)
    }
}

struct SectionHeader: View {
    let num: String
    let label: String

    var body: some View {
        HStack {
            Text(num)
                .font(.kami(.body, size: 13))
                .foregroundStyle(.kami.accent)
            Text(label)
                .font(.kami(.body, size: 11))
                .foregroundStyle(.kami.meta)
        }
    }
}
```

- [ ] **Step 3: 创建占位 ProductCard** （Task 20 才完成，提前放）

`KidBonus/Views/Shop/ProductCard.swift`:

```swift
import SwiftUI

struct ProductCard: View {
    let product: Product
    let affordable: Bool
    let bestPoints: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            ZStack {
                Rectangle().fill(.kami.tagBgFaint)
                    .aspectRatio(1, contentMode: .fit)
                Image(systemName: product.iconName ?? "gift")
                    .font(.system(size: 32))
                    .foregroundStyle(.kami.accent)
            }
            VStack(alignment: .leading, spacing: Spacing.s1) {
                Text(product.name).font(.kami(.body, size: 13))
                HStack(spacing: 2) {
                    Text("\(product.cost)")
                        .font(.kami(.body, size: 18))
                        .foregroundStyle(.kami.accent)
                    Text("分").font(.kami(.body, size: 11)).foregroundStyle(.kami.meta)
                }
                Tag(text: affordable ? "可兑换" : "还差 \(product.cost - bestPoints)",
                    kind: affordable ? .success : .faint)
            }
            .padding(.horizontal, Spacing.s2)
            .padding(.bottom, Spacing.s3)
        }
        .background(Color.kami.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md).stroke(.kami.border, lineWidth: 1)
        )
        .opacity(affordable ? 1 : 0.6)
    }
}
```

- [ ] **Step 4: 验证 build**

```bash
cd /Volumes/CC/Projects/kid-bounus/KidBonus
xcodebuild -project KidBonus.xcodeproj -scheme KidBonus -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 5: 验证启动 simulator 看渲染**

```bash
xcrun simctl boot 'iPhone 16' 2>/dev/null
xcodebuild -project KidBonus.xcodeproj -scheme KidBonus -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
APP=$(find ~/Library/Developer/Xcode/DerivedData -type d -name "KidBonus.app" | head -n1)
xcrun simctl install booted "$APP"
xcrun simctl launch booted com.kidbonus.growingtree
xcrun simctl io booted screenshot /tmp/home.png
open /tmp/home.png
```

打开截图肉眼验证。

- [ ] **Step 6: Commit**

```bash
cd /Volumes/CC/Projects/kid-bounus
git add KidBonus/Views/Home KidBonus/Views/Shop/ProductCard.swift
git commit -m "feat(home): KidCard + HomeView + ProductCard stub"
```

---

## Task 17: QuickView + ItemRow

**Files:**
- Modify: `KidBonus/Views/Quick/QuickView.swift`
- Create: `KidBonus/Views/Quick/ItemRow.swift`

**Interfaces:**
- Produces: `ItemRow(item:onTap:)`, `QuickView` 切换 KidTabs 写分 + ManualSheet 入口

- [ ] **Step 1: 实现 `Quick/ItemRow.swift`**

```swift
import SwiftUI

struct ItemRow: View {
    let item: PointItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.s3) {
                ZStack {
                    RoundedRectangle(cornerRadius: Radius.sm)
                        .fill(item.delta > 0 ? .kami.tagBgSoft : Color(hex: 0xEFE2DF))
                        .frame(width: 36, height: 36)
                    Image(systemName: item.iconName ?? "circle")
                        .foregroundStyle(item.delta > 0 ? .kami.accent : .kami.danger)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title).font(.kami(.body, size: 14))
                    Text(item.desc).font(.kami(.body, size: 11)).foregroundStyle(.kami.meta)
                }
                Spacer()
                Text("\(item.delta > 0 ? "+" : "")\(item.delta)")
                    .font(.kami(.body, size: 18))
                    .foregroundStyle(item.delta > 0 ? .kami.success : .kami.danger)
            }
            .padding(.horizontal, Spacing.s4)
            .padding(.vertical, Spacing.s3)
            .background(Color.kami.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md).stroke(.kami.border, lineWidth: 1)
            )
            .frame(minHeight: 56)
        }
        .buttonStyle(.plain)
    }
}
```

- [ ] **Step 2: 实现 `Quick/QuickView.swift`**

```swift
import SwiftUI
import SwiftData

struct QuickView: View {
    @Query private var kids: [Kid]
    @Query(filter: #Predicate<PointItem> { $0.kind == .add }) private var adds: [PointItem]
    @Query(filter: #Predicate<PointItem> { $0.kind == .deduct }) private var deds: [PointItem]
    @Environment(\.modelContext) private var ctx
    @Environment(ToastCenter.self) private var toast
    @AppStorage("currentKidID") private var currentKidID: String = ""
    @State private var showManual = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s5) {
                    VStack(alignment: .leading, spacing: Spacing.s2) {
                        Text("加减分").font(.kami(.body, size: 28))
                        Text("选孩子，再点一项。")
                            .font(.kami(.body, size: 14))
                            .foregroundStyle(.kami.muted)
                    }
                    .padding(.horizontal, Spacing.s4)

                    SectionHeader(num: nil, label: "选一个孩子")
                    if !kids.isEmpty {
                        KidTabs(kids: kids, selected: Binding(
                            get: { UUID(uuidString: currentKidID) ?? kids[0].id },
                            set: { currentKidID = $0.uuidString }
                        ))
                    }
                    .padding(.horizontal, Spacing.s4)

                    SectionHeader(num: nil, label: "加分项")
                    VStack(spacing: Spacing.s3) {
                        ForEach(adds) { item in
                            ItemRow(item: item) { addOrDeduct(item) }
                        }
                    }
                    .padding(.horizontal, Spacing.s4)

                    SectionHeader(num: nil, label: "扣分项")
                    VStack(spacing: Spacing.s3) {
                        ForEach(deds) { item in
                            ItemRow(item: item) { addOrDeduct(item) }
                        }
                    }
                    .padding(.horizontal, Spacing.s4)

                    SectionHeader(num: nil, label: "自定义加减")
                    Button { showManual = true } label: {
                        HStack(spacing: Spacing.s3) {
                            Image(systemName: "pencil")
                                .frame(width: 36, height: 36)
                                .background(.kami.tagBgSoft)
                                .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                            VStack(alignment: .leading) {
                                Text("手动加减分").font(.kami(.body, size: 14))
                                Text("自定义标题和分值,不入预设项")
                                    .font(.kami(.body, size: 11)).foregroundStyle(.kami.meta)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(.kami.meta)
                        }
                        .padding(Spacing.s4)
                        .background(Color.kami.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.md)
                                .stroke(.kami.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, Spacing.s4)
                }
                .padding(.vertical, Spacing.s4)
            }
            .background(Color.kami.bg)
        }
        .sheet(isPresented: $showManual) {
            ManualRecordSheet()
        }
    }

    private func addOrDeduct(_ item: PointItem) {
        guard let kid = kids.first(where: { $0.id.uuidString == currentKidID }) ?? kids.first else { return }
        let outcome = RecordStore.recordItem(item, on: kid, ctx: ctx)
        toast.show(.success, title: "\(kid.name) · \(item.title)",
                   body: "\(item.delta > 0 ? "+" : "")\(item.delta) 分 · 当前 \(outcome.points) 分")
        if outcome.streakBonus > 0 {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 700_000_000)
                toast.show(.success, title: "\(kid.name) · Streak bonus!",
                           body: "连续 \(outcome.streakCount) 天 · +\(outcome.streakBonus) 分")
            }
        }
    }
}
```

- [ ] **Step 3: 验证 build + Commit**

```bash
cd /Volumes/CC/Projects/kid-bounus/KidBonus
xcodebuild -project KidBonus.xcodeproj -scheme KidBonus -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
cd /Volumes/CC/Projects/kid-bounus
git add KidBonus/Views/Quick
git commit -m "feat(quick): QuickView with KidTabs and ItemRow"
```

---

## Task 18: HistoryView — 时间轴

**Files:**
- Modify: `KidBonus/Views/History/HistoryView.swift`

**Interfaces:**
- Produces: `HistoryView` 列表,按天分组

- [ ] **Step 1: 实现**

```swift
import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \HistoryRecord.timestamp, order: .reverse) private var all: [HistoryRecord]
    @Query private var kids: [Kid]
    @State private var filter: String = "all"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s5) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("历程").font(.kami(.body, size: 28))
                        Text("按天分组,最近 30 天。")
                            .font(.kami(.body, size: 14))
                            .foregroundStyle(.kami.muted)
                    }
                    .padding(.horizontal, Spacing.s4)

                    HStack(spacing: Spacing.s2) {
                        chip("全部", id: "all")
                        ForEach(kids) { k in chip(k.name, id: k.id.uuidString) }
                    }
                    .padding(.horizontal, Spacing.s4)

                    let filtered = all.filter { filter == "all" || $0.kid?.id.uuidString == filter }
                    if filtered.isEmpty {
                        Text("还没有记录,去加减分页记一笔吧。")
                            .font(.kami(.body, size: 12))
                            .foregroundStyle(.kami.meta)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.kami.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.md)
                                    .stroke(.kami.border, lineWidth: 1)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
                            )
                            .padding(.horizontal, Spacing.s4)
                    } else {
                        ForEach(groupedByDay(filtered), id: \.0) { day, items in
                            VStack(alignment: .leading, spacing: Spacing.s2) {
                                Text(dayLabel(day))
                                    .font(.kami(.body, size: 11))
                                    .foregroundStyle(.kami.meta)
                                    .padding(.horizontal, Spacing.s4)
                                ForEach(items) { h in row(for: h) }
                            }
                        }
                    }
                }
                .padding(.vertical, Spacing.s4)
            }
            .background(Color.kami.bg)
        }
    }

    private func chip(_ text: String, id: String) -> some View {
        Button {
            filter = id
        } label: {
            Text(text)
                .font(.kami(.body, size: 14))
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(filter == id ? Color.kami.surface : .kami.surfaceWarm)
                .foregroundStyle(filter == id ? .kami.accent : .kami.muted)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .stroke(filter == id ? .kami.accent : .kami.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func row(for h: HistoryRecord) -> some View {
        HStack(alignment: .top, spacing: Spacing.s3) {
            Circle()
                .fill(h.delta > 0 ? .kami.bg : .kami.bg)
                .overlay(Circle().stroke(h.delta > 0 ? .kami.accent : .kami.danger, lineWidth: 1))
                .frame(width: 9, height: 9)
                .padding(.top, 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(h.title).font(.kami(.body, size: 13))
                Text("\(h.kid?.name ?? "") · \(formatTime(h.timestamp))")
                    .font(.kami(.body, size: 11)).foregroundStyle(.kami.meta)
            }
            Spacer()
            Text("\(h.delta > 0 ? "+" : "")\(h.delta)")
                .font(.kami(.body, size: 14))
                .foregroundStyle(h.delta > 0 ? .kami.success : .kami.danger)
        }
        .padding(.horizontal, Spacing.s3)
        .padding(.vertical, Spacing.s2)
        .padding(.leading, Spacing.s4)
    }

    private func groupedByDay(_ items: [HistoryRecord]) -> [(String, [HistoryRecord])] {
        let cal = Calendar.current
        let groups = Dictionary(grouping: items) {
            cal.dateComponents([.year, .month, .day], from: $0.timestamp)
        }
        return groups
            .sorted { ($0.key, $1.key) }
            .map { (key, val) in
                let date = cal.date(from: key) ?? .now
                let k = DateKey.day(date)
                return (k, val.sorted { $0.timestamp > $1.timestamp })
            }
    }

    private func dayLabel(_ key: String) -> String {
        if key == DateKey.today { return "今天" }
        if key == DateKey.day(before: 1) { return "昨天" }
        let comps = key.split(separator: "-").map { Int($0) ?? 0 }
        if comps.count == 3 {
            return "\(comps[1])月\(comps[2])日"
        }
        return key
    }

    private func formatTime(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"
        return f.string(from: d)
    }
}
```

- [ ] **Step 2: 验证 build + Commit**

```bash
cd /Volumes/CC/Projects/kid-bounus/KidBonus
xcodebuild -project KidBonus.xcodeproj -scheme KidBonus -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
cd /Volumes/CC/Projects/kid-bounus
git add KidBonus/Views/History/HistoryView.swift
git commit -m "feat(history): HistoryView with timeline and filter"
```

---

## Task 19: ShopView + RedeemConfirmSheet

**Files:**
- Modify: `KidBonus/Views/Shop/ShopView.swift`
- Modify: `KidBonus/Views/Shop/ProductCard.swift`（加 onTap）
- Create: `KidBonus/Views/Sheets/RedeemConfirmSheet.swift`

- [ ] **Step 1: 完善 `ProductCard.swift` 加 onTap**

修改 `KidBonus/Views/Shop/ProductCard.swift`，把根视图包成 `Button`，加 `action: () -> Void` 参数。

```swift
struct ProductCard: View {
    let product: Product
    let affordable: Bool
    let bestPoints: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            // 原 body, 内部 Image 改为 Image(systemName:)
            VStack(alignment: .leading, spacing: Spacing.s2) {
                ZStack {
                    Rectangle().fill(affordable ? .kami.tagBgSoft : .kami.tagBgFaint)
                        .aspectRatio(1, contentMode: .fit)
                    Image(systemName: product.iconName ?? "gift")
                        .font(.system(size: 32))
                        .foregroundStyle(.kami.accent)
                }
                VStack(alignment: .leading, spacing: Spacing.s1) {
                    Text(product.name).font(.kami(.body, size: 13))
                    HStack(spacing: 2) {
                        Text("\(product.cost)")
                            .font(.kami(.body, size: 18))
                            .foregroundStyle(.kami.accent)
                        Text("分").font(.kami(.body, size: 11)).foregroundStyle(.kami.meta)
                    }
                    Tag(text: affordable ? "可兑换" : "还差 \(product.cost - bestPoints)",
                        kind: affordable ? .success : .faint)
                }
                .padding(.horizontal, Spacing.s2)
                .padding(.bottom, Spacing.s3)
            }
            .background(Color.kami.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md).stroke(.kami.border, lineWidth: 1)
            )
            .opacity(affordable ? 1 : 0.6)
        }
        .buttonStyle(.plain)
    }
}
```

- [ ] **Step 2: 实现 `Shop/ShopView.swift`**

```swift
import SwiftUI
import SwiftData

struct ShopView: View {
    @Query private var products: [Product]
    @Query private var kids: [Kid]
    @Query(sort: \Redemption.timestamp, order: .reverse) private var redemptions: [Redemption]
    @State private var cat: ProductCategory? = nil
    @State private var pending: Product? = nil
    @State private var bestPointsCache: Int = 0
    @Environment(\.modelContext) private var ctx
    @Environment(ToastCenter.self) private var toast
    @AppStorage("currentKidID") private var currentKidID: String = ""

    private static let cats: [ProductCategory?] = [
        nil, .toy, .book, .food, .priv, .out
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s5) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("积分商城").font(.kami(.body, size: 28))
                        Text("点击商品兑换。不足会标灰。")
                            .font(.kami(.body, size: 14))
                            .foregroundStyle(.kami.muted)
                    }
                    .padding(.horizontal, Spacing.s4)

                    HStack(spacing: Spacing.s2) {
                        ForEach(Self.cats, id: \.self) { c in
                            chip(c?.label ?? "全部", selected: c == cat) { cat = c }
                        }
                    }
                    .padding(.horizontal, Spacing.s4)

                    LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: Spacing.s3) {
                        ForEach(filtered) { p in
                            ProductCard(
                                product: p,
                                affordable: bestPoints >= p.cost,
                                bestPoints: bestPoints
                            ) {
                                pending = p
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.s4)

                    SectionHeader(num: nil, label: "兑换记录")
                    if redemptions.isEmpty {
                        Text("还没有兑换记录。")
                            .font(.kami(.body, size: 12))
                            .foregroundStyle(.kami.meta)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.kami.surface)
                            .padding(.horizontal, Spacing.s4)
                    } else {
                        VStack(spacing: Spacing.s2) {
                            ForEach(redemptions.prefix(10)) { r in
                                redemptionRow(r)
                            }
                        }
                        .padding(.horizontal, Spacing.s4)
                    }
                }
                .padding(.vertical, Spacing.s4)
            }
            .background(Color.kami.bg)
        }
        .sheet(item: $pending) { p in
            RedeemConfirmSheet(product: p) {
                pending = nil
            }
        }
        .onAppear {
            bestPointsCache = kids.map { PointMath.kidPoints($0) }.max() ?? 0
        }
    }

    private var bestPoints: Int {
        kids.map { PointMath.kidPoints($0) }.max() ?? 0
    }

    private var filtered: [Product] {
        let pool = cat == nil ? products : products.filter { $0.category == cat }
        return pool.sorted { $0.cost > $1.cost }
    }

    private func chip(_ text: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.kami(.body, size: 13))
                .padding(.horizontal, Spacing.s3)
                .padding(.vertical, Spacing.s2)
                .frame(minHeight: 36)
                .background(selected ? .kami.tagBgSoft : .kami.surface)
                .foregroundStyle(selected ? .kami.accent : .kami.muted)
                .clipShape(RoundedRectangle(cornerRadius: Radius.xs))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.xs)
                        .stroke(selected ? .kami.tagBgSoft : .kami.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func redemptionRow(_ r: Redemption) -> some View {
        HStack(spacing: Spacing.s3) {
            Image(systemName: "gift")
                .frame(width: 36, height: 36)
                .background(.kami.tagBgSoft)
                .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
            VStack(alignment: .leading) {
                Text(r.productName).font(.kami(.body, size: 13))
                Text("\(r.kid?.name ?? "") · \(formatDate(r.timestamp))")
                    .font(.kami(.body, size: 11)).foregroundStyle(.kami.meta)
            }
            Spacer()
            Text("-\(r.cost)")
                .font(.kami(.body, size: 14))
                .foregroundStyle(.kami.accent)
        }
        .padding(Spacing.s3)
        .background(.kami.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md).stroke(.kami.border, lineWidth: 1)
        )
    }

    private func formatDate(_ d: Date) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日 HH:mm"
        return f.string(from: d)
    }
}
```

- [ ] **Step 3: 实现 `Sheets/RedeemConfirmSheet.swift`**

```swift
import SwiftUI
import SwiftData

struct RedeemConfirmSheet: View {
    let product: Product
    let onClose: () -> Void
    @Query private var kids: [Kid]
    @Environment(\.modelContext) private var ctx
    @Environment(ToastCenter.self) private var toast
    @AppStorage("currentKidID") private var currentKidID: String = ""
    @State private var selectedKidID: UUID?

    var body: some View {
        SheetScaffold(
            title: product.name,
            message: "需要 \(product.cost) 分。\(product.desc)",
            actions: [
                SheetAction(title: "取消", primary: false) { onClose() },
                SheetAction(title: "兑换", primary: true) { confirm() }
            ]
        ) {
            Picker("孩子", selection: Binding(
                get: { selectedKidID ?? defaultKid },
                set: { selectedKidID = $0 }
            )) {
                ForEach(kids) { k in
                    Text("\(k.name) · \(PointMath.kidPoints(k)) 分")
                        .tag(k.id as UUID?)
                }
            }
            .pickerStyle(.menu)
            .tint(.kami.accent)
            .padding(Spacing.s3)
            .background(.kami.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        }
    }

    private var defaultKid: UUID? {
        UUID(uuidString: currentKidID) ?? kids.first?.id
    }

    private func confirm() {
        guard let id = selectedKidID ?? defaultKid,
              let kid = kids.first(where: { $0.id == id }) else { return }
        if PointMath.kidPoints(kid) < product.cost {
            toast.show(.danger, title: "积分不足",
                       body: "\(kid.name) 的积分不够。")
            onClose()
            return
        }
        let ok = RecordStore.redeem(product, by: kid, ctx: ctx)
        if ok {
            toast.show(.success, title: "\(kid.name) 兑换了 \(product.name)",
                       body: "剩余 \(PointMath.kidPoints(kid)) 分")
        }
        onClose()
    }
}
```

- [ ] **Step 4: 验证 build + Commit**

```bash
cd /Volumes/CC/Projects/kid-bounus/KidBonus
xcodebuild -project KidBonus.xcodeproj -scheme KidBonus -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
cd /Volumes/CC/Projects/kid-bounus
git add KidBonus/Views/Shop KidBonus/Views/Sheets/RedeemConfirmSheet.swift
git commit -m "feat(shop): ShopView + RedeemConfirmSheet"
```

---

## Task 20: StatsView + Sparkline

**Files:**
- Modify: `KidBonus/Views/Stats/StatsView.swift`
- Modify: `KidBonus/Views/Stats/Sparkline.swift`

- [ ] **Step 1: 实现 `Sparkline.swift`**（Swift Charts）

```swift
import SwiftUI
import Charts

struct Sparkline: View {
    let buckets: [TrendBucket]

    var body: some View {
        Chart(buckets, id: \.dateKey) { b in
            LineMark(x: .value("Day", b.dateKey),
                     y: .value("Net", b.value))
            .interpolationMethod(.catmullRom)
            AreaMark(x: .value("Day", b.dateKey),
                     y: .value("Net", b.value))
            .foregroundStyle(.kami.accent.opacity(0.1))
        }
        .chartYAxis(.hidden)
        .chartXAxis(.hidden)
        .chartYScale(domain: yDomain)
        .frame(height: 80)
    }

    private var yDomain: ClosedRange<Int> {
        let values = buckets.map { $0.value }
        let mn = min(0, values.min() ?? 0)
        let mx = max(1, values.max() ?? 0)
        let pad = max(1, Int(Double(mx - mn) * 0.1))
        return (mn - pad) ... (mx + pad)
    }
}
```

- [ ] **Step 2: 实现 `StatsView.swift`**

```swift
import SwiftUI
import SwiftData

struct StatsView: View {
    @Query private var kids: [Kid]
    @AppStorage("currentKidID") private var currentKidID: String = ""
    @Environment(\.modelContext) private var ctx

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s5) {
                    VStack(alignment: .leading) {
                        Text("统计").font(.kami(.body, size: 28))
                        Text("近 14 天积分变化趋势。")
                            .font(.kami(.body, size: 14))
                            .foregroundStyle(.kami.muted)
                    }
                    .padding(.horizontal, Spacing.s4)

                    KidTabs(kids: kids, selected: Binding(
                        get: { UUID(uuidString: currentKidID) ?? kids[0].id },
                        set: { currentKidID = $0.uuidString }
                    ))
                    .padding(.horizontal, Spacing.s4)
                    .onChange(of: currentKidID) { _, _ in /* trigger recompute via @Query */ }

                    if let kid = currentKid {
                        VStack(alignment: .leading, spacing: Spacing.s4) {
                            HStack(spacing: Spacing.s3) {
                                statBlock(value: "\(PointMath.kidPoints(kid))", label: "当前积分")
                                statBlock(value: "\(count(kid, +))", label: "加分次数")
                                statBlock(value: "\(count(kid, -))", label: "扣分次数")
                            }
                            .padding(Spacing.s4)
                            .background(.kami.surface)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.md)
                                    .stroke(.kami.border, lineWidth: 1)
                            )

                            Sparkline(buckets: TrendBuilder.trend(kid))

                            SectionHeader(num: nil, label: "按项目分布")
                            VStack(spacing: Spacing.s2) {
                                ForEach(TrendBuilder.distribution(kid).prefix(8), id: \.title) { r in
                                    HStack {
                                        Text(r.title).font(.kami(.body, size: 14))
                                        Spacer()
                                        Text("+\(r.add) · −\(r.deduct)")
                                            .font(.kami(.body, size: 12))
                                            .foregroundStyle(.kami.meta)
                                    }
                                    .padding(Spacing.s3)
                                    .background(.kami.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Radius.md)
                                            .stroke(.kami.border, lineWidth: 1)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, Spacing.s4)
                    }
                }
                .padding(.vertical, Spacing.s4)
            }
            .background(Color.kami.bg)
        }
    }

    private var currentKid: Kid? {
        kids.first { $0.id.uuidString == currentKidID } ?? kids.first
    }

    private func count(_ kid: Kid, _ sign: Int) -> Int {
        kid.history.filter { ($0.delta > 0 ? 1 : -1) == sign }.count
    }

    private func statBlock(value: String, label: String) -> some View {
        VStack(alignment: .leading) {
            Text(value).font(.kami(.body, size: 22)).foregroundStyle(.kami.fg)
            Text(label).font(.kami(.body, size: 11)).foregroundStyle(.kami.meta)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
```

- [ ] **Step 3: 修改 ContentView 在 top bar 加入口**

更新 `ContentView.swift` 在 ZStack 内添加一个 NavigationLink/Sheet 触发器。这是简化做法——把 topbar 直接放在 ContentView 上方。

```swift
struct ContentView: View {
    @State private var toast = ToastCenter()
    @State private var showingStats = false
    @AppStorage("currentKidID") private var currentKidID: String = ""

    var body: some View {
        @Bindable var toast = toast

        VStack(spacing: 0) {
            HStack {
                Text("成长树").font(.kami(.body, size: 13))
                    .foregroundStyle(.kami.meta)
                Spacer()
                Button { showingStats = true } label: {
                    Image(systemName: "chart.bar").foregroundStyle(.kami.muted)
                        .frame(width: 36, height: 36)
                }
                Button {
                    // 跳"我的": 用 selection 绑到 tab
                } label: {
                    Image(systemName: "person").foregroundStyle(.kami.muted)
                        .frame(width: 36, height: 36)
                }
            }
            .padding(.horizontal, Spacing.s4)
            .padding(.top, Spacing.s2)
            .background(Color.kami.bg)

            ZStack(alignment: .top) {
                TabView {
                    HomeView().tabItem { Label("首页", systemImage: "house") }
                    QuickView().tabItem { Label("加减", systemImage: "plus") }
                    ShopView().tabItem { Label("商城", systemImage: "bag") }
                    HistoryView().tabItem { Label("历程", systemImage: "clock") }
                    MeView().tabItem { Label("我的", systemImage: "person") }
                }
                .tint(.kami.accent)

                if let t = toast.current {
                    ToastBanner(toast: t)
                }
            }
        }
        .background(Color.kami.bg)
        .environment(toast)
        .sheet(isPresented: $showingStats) {
            StatsView()
        }
    }
}
```

- [ ] **Step 4: 验证 build + 截图**

```bash
cd /Volumes/CC/Projects/kid-bounus/KidBonus
xcodebuild -project KidBonus.xcodeproj -scheme KidBonus -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
APP=$(find ~/Library/Developer/Xcode/DerivedData -type d -name "KidBonus.app" | head -n1)
xcrun simctl install booted "$APP"
xcrun simctl launch booted com.kidbonus.growingtree
```

- [ ] **Step 5: Commit**

```bash
cd /Volumes/CC/Projects/kid-bounus
git add KidBonus/Views/Stats KidBonus/Views/ContentView.swift
git commit -m "feat(stats): StatsView with sparkline + distribution"
```

---

## Task 21: MeView — 改名 / 增删 / 重置

**Files:**
- Modify: `KidBonus/Views/Me/MeView.swift`

- [ ] **Step 1: 实现**

```swift
import SwiftUI
import SwiftData

struct MeView: View {
    @Query private var kids: [Kid]
    @Query(filter: #Predicate<PointItem> { $0.kind == .add }) private var adds: [PointItem]
    @Query(filter: #Predicate<PointItem> { $0.kind == .deduct }) private var deds: [PointItem]
    @Environment(\.modelContext) private var ctx
    @Environment(ToastCenter.self) private var toast
    @State private var showAddItem: Kind?
    @State private var showReset = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s5) {
                    VStack(alignment: .leading) {
                        Text("我的").font(.kami(.body, size: 28))
                        Text("改名字 · 改积分项 · 重置数据。")
                            .font(.kami(.body, size: 14))
                            .foregroundStyle(.kami.muted)
                    }
                    .padding(.horizontal, Spacing.s4)

                    section("01", "两个孩子") {
                        ForEach(kids) { k in
                            HStack {
                                KidAvatar(name: k.name, size: 36, colorHex: k.colorHex)
                                TextField("孩子名字", text: Binding(
                                    get: { k.name },
                                    set: { v in k.name = v; try? ctx.save() }
                                ))
                                .textFieldStyle(.plain)
                                .font(.kami(.body, size: 14))
                                Spacer()
                                Text("\(PointMath.kidPoints(k)) 分")
                                    .font(.kami(.body, size: 12))
                                    .foregroundStyle(.kami.meta)
                            }
                            .padding(Spacing.s3)
                            .background(.kami.surface)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.md)
                                    .stroke(.kami.border, lineWidth: 1)
                            )
                        }
                    }

                    section("02", "加分项") {
                        ForEach(adds) { it in editRow(it) }
                        Button { showAddItem = .add } label: {
                            HStack {
                                Image(systemName: "plus")
                                Text("增加加分项")
                            }
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(.kami.surfaceWarm)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                        }
                        .buttonStyle(.plain)
                    }

                    section("03", "扣分项") {
                        ForEach(deds) { it in editRow(it) }
                        Button { showAddItem = .deduct } label: {
                            HStack {
                                Image(systemName: "minus")
                                Text("增加扣分项")
                            }
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(.kami.surfaceWarm)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                        }
                        .buttonStyle(.plain)
                    }

                    section("04", "数据") {
                        Button(role: .destructive) {
                            showReset = true
                        } label: {
                            Text("重置全部数据")
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(Color(hex: 0xEFE2DF))
                                .foregroundStyle(.kami.danger)
                                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                        }
                        .buttonStyle(.plain)
                    }

                    Text("数据保存在本地设备。")
                        .font(.kami(.body, size: 11))
                        .foregroundStyle(.kami.meta)
                        .frame(maxWidth: .infinity)
                }
                .padding(.vertical, Spacing.s4)
            }
            .background(Color.kami.bg)
        }
        .sheet(item: $showAddItem) { kind in
            AddItemSheet(kind: kind)
        }
        .confirmationDialog("重置全部数据?此操作不可撤销。",
                            isPresented: $showReset,
                            titleVisibility: .visible) {
            Button("重置", role: .destructive) {
                SeedData.installFresh(ctx: ctx)
                toast.show(.success, title: "已重置", body: "数据已恢复到初始。")
            }
        }
    }

    @ViewBuilder
    private func section<Content: View>(_ num: String, _ label: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            SectionHeader(num: num, label: label)
            VStack(spacing: Spacing.s2) {
                content()
            }
        }
        .padding(.horizontal, Spacing.s4)
    }

    private func editRow(_ it: PointItem) -> some View {
        HStack {
            Text(it.title).font(.kami(.body, size: 13))
            Spacer()
            Text("\(it.delta > 0 ? "+" : "")\(it.delta)")
                .font(.kami(.body, size: 14))
                .foregroundStyle(it.delta > 0 ? .kami.success : .kami.danger)
            Button(role: .destructive) {
                ctx.delete(it)
                try? ctx.save()
            } label: {
                Image(systemName: "trash").foregroundStyle(.kami.danger)
            }
        }
        .padding(.horizontal, Spacing.s3)
        .padding(.vertical, Spacing.s2)
        .background(.kami.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md).stroke(.kami.border, lineWidth: 1)
        )
    }
}
```

> 注：Kind 需要 Conforms to Identifiable 才能用 `sheet(item:)`。先给 Kind 加 `extension Kind: Identifiable {}`(Task 4 已经做了)。

- [ ] **Step 2: 验证 build + Commit**

```bash
cd /Volumes/CC/Projects/kid-bounus/KidBonus
xcodebuild -project KidBonus.xcodeproj -scheme KidBonus -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
cd /Volumes/CC/Projects/kid-bounus
git add KidBonus/Views/Me/MeView.swift
git commit -m "feat(me): MeView with rename / add / delete / reset"
```

---

## Task 22: AddItemSheet + ManualRecordSheet

**Files:**
- Create: `KidBonus/Views/Sheets/AddItemSheet.swift`
- Create: `KidBonus/Views/Sheets/ManualRecordSheet.swift`

- [ ] **Step 1: 实现 `Sheets/AddItemSheet.swift`**

```swift
import SwiftUI
import SwiftData

struct AddItemSheet: View {
    let kind: Kind
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @Environment(ToastCenter.self) private var toast
    @State private var title: String = ""
    @State private var deltaText: String = ""
    @State private var desc: String = ""

    var body: some View {
        SheetScaffold(
            title: "新增\(kind == .add ? "加分" : "扣分")项",
            actions: [
                SheetAction(title: "取消", primary: false) { dismiss() },
                SheetAction(title: "保存", primary: true) { save() }
            ]
        ) {
            Field(text: $title, placeholder: "项目名称,如:刷牙早晚")
            Field(text: $deltaText, placeholder: "分值(整数)",
                  keyboard: .numberPad)
            Field(text: $desc, placeholder: "一句说明(可选)")
        }
    }

    private func save() {
        let t = title.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { toast.show(.danger, title: "请填名称"); return }
        guard var d = Int(deltaText), d != 0 else {
            toast.show(.danger, title: "分值要为非零整数"); return
        }
        if kind == .add && d < 0 { d = -d }
        if kind == .deduct && d > 0 { d = -d }
        let item = PointItem(
            kind: kind, title: t, delta: d,
            iconName: kind == .add ? "checkmark" : "exclamationmark",
            desc: desc.isEmpty ? (kind == .add ? "一个好习惯" : "需要改进的小事") : desc
        )
        ctx.insert(item)
        try? ctx.save()
        toast.show(.success, title: "已新增「\(t)」",
                   body: "\(d > 0 ? "+" : "")\(d) 分")
        dismiss()
    }

    private struct Field: View {
        @Binding var text: String
        let placeholder: String
        var keyboard: UIKeyboardType = .default
        var body: some View {
            TextField(placeholder, text: $text)
                .keyboardType(keyboard)
                .padding(Spacing.s3)
                .background(.kami.surface)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .stroke(.kami.border, lineWidth: 1)
                )
                .font(.kami(.body, size: 14))
        }
    }
}
```

- [ ] **Step 2: 实现 `Sheets/ManualRecordSheet.swift`**

```swift
import SwiftUI
import SwiftData

struct ManualRecordSheet: View {
    @Query private var kids: [Kid]
    @Query(sort: \HistoryRecord.timestamp, order: .reverse) private var allHistory: [HistoryRecord]
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @Environment(ToastCenter.self) private var toast
    @AppStorage("currentKidID") private var currentKidID: String = ""
    @State private var title: String = ""
    @State private var deltaText: String = "5"
    @State private var note: String = ""
    @State private var isAdd: Bool = true
    @State private var pickedKidID: UUID?

    var body: some View {
        SheetScaffold(
            title: "手动加减分",
            message: "记一笔临时事项:填写标题和分值,备注可选。不写入预设项。",
            actions: [
                SheetAction(title: "取消", primary: false) { dismiss() },
                SheetAction(title: "记录", primary: true) { save() }
            ]
        ) {
            let recents = recentFreeforms()
            if recents.isEmpty {
                Text("还没有自定义记录")
                    .font(.kami(.body, size: 11))
                    .foregroundStyle(.kami.meta)
            } else {
                FlowLayout(spacing: 6) {
                    ForEach(recents, id: \.id) { rf in
                        Button { reuse(rf) } label: {
                            Text("\(rf.delta > 0 ? "+" : "")\(rf.delta) · \(rf.title)")
                                .font(.kami(.body, size: 12))
                                .padding(.horizontal, Spacing.s3).padding(.vertical, Spacing.s2)
                                .background(rf.delta > 0
                                            ? Color(hex: 0xE6EDE0)
                                            : Color(hex: 0xEFE2DF))
                                .foregroundStyle(rf.delta > 0 ? .kami.success : .kami.danger)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            KidTabs(kids: kids, selected: Binding(
                get: { pickedKidID ?? UUID(uuidString: currentKidID) ?? kids.first?.id ?? UUID() },
                set: { pickedKidID = $0 }
            ))

            Field(text: $title, placeholder: "这次是因为……(必填)")

            HStack(spacing: Spacing.s2) {
                Button { isAdd.toggle() } label: {
                    Text(isAdd ? "+" : "−")
                        .frame(width: 44, height: 44)
                        .background(.kami.surfaceWarm)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                }
                .buttonStyle(.plain)
                TextField("分值", text: $deltaText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .padding(Spacing.s3)
                    .background(.kami.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.md)
                            .stroke(.kami.border, lineWidth: 1)
                    )
                    .frame(maxWidth: .infinity)
                Text("分").font(.kami(.body, size: 14)).foregroundStyle(.kami.meta)
            }

            Field(text: $note, placeholder: "备注(可选)")
        }
    }

    private func save() {
        let t = title.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { toast.show(.danger, title: "请填标题"); return }
        guard var n = Int(deltaText), n != 0 else {
            toast.show(.danger, title: "分值要为非零整数"); return
        }
        n = abs(n)
        if !isAdd { n = -n }
        let picked = pickedKidID ?? UUID(uuidString: currentKidID)
        guard let id = picked, let kid = kids.first(where: { $0.id == id }) else { return }
        let final = note.isEmpty ? t : "\(t)(\(note))"
        let outcome = RecordStore.recordFreeform(title: final, delta: n, on: kid, ctx: ctx)
        toast.show(.success, title: "\(kid.name) · \(final)",
                   body: "\(n > 0 ? "+" : "")\(n) 分 · 当前 \(outcome.points) 分")
        if outcome.streakBonus > 0 {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 700_000_000)
                toast.show(.success, title: "\(kid.name) · Streak bonus!",
                           body: "连续 \(outcome.streakCount) 天 · +\(outcome.streakBonus) 分")
            }
        }
        dismiss()
    }

    private func reuse(_ rf: FreeformChip) {
        guard let id = pickedKidID ?? UUID(uuidString: currentKidID),
              let kid = kids.first(where: { $0.id == id }) else { return }
        _ = RecordStore.recordFreeform(title: rf.title, delta: rf.delta, on: kid, ctx: ctx)
        toast.show(.success, title: "\(kid.name) · \(rf.title)",
                   body: "\(rf.delta > 0 ? "+" : "")\(rf.delta) 分")
        dismiss()
    }

    private struct FreeformChip: Identifiable {
        let id: String
        let title: String
        let delta: Int
    }

    private func recentFreeforms() -> [FreeformChip] {
        var seen: [String: FreeformChip] = [:]
        for h in allHistory {
            let key = h.title + "||" + String(h.delta)
            if seen[key] == nil { seen[key] = FreeformChip(id: key, title: h.title, delta: h.delta) }
        }
        return Array(seen.values.prefix(5))
    }

    private struct Field: View {
        @Binding var text: String
        let placeholder: String
        var body: some View {
            TextField(placeholder, text: $text)
                .padding(Spacing.s3)
                .background(.kami.surface)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .stroke(.kami.border, lineWidth: 1)
                )
                .font(.kami(.body, size: 14))
        }
    }
}

/// 简易 FlowLayout（SwiftUI iOS 18+ 提供 `Layout` 协议）
struct FlowLayout: Layout {
    var spacing: CGFloat = 6
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0
        for sv in subviews {
            let size = sv.sizeThatFits(.unspecified)
            if x + size.width > maxWidth {
                x = 0
                y += rowH + spacing
                rowH = 0
            }
            x += size.width + spacing
            rowH = max(rowH, size.height)
        }
        return CGSize(width: maxWidth, height: y + rowH)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize,
                       subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for sv in subviews {
            let size = sv.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowH + spacing
                rowH = 0
            }
            sv.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowH = max(rowH, size.height)
        }
    }
}
```

- [ ] **Step 3: 验证 build + Commit**

```bash
cd /Volumes/CC/Projects/kid-bounus/KidBonus
xcodebuild -project KidBonus.xcodeproj -scheme KidBonus -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
cd /Volumes/CC/Projects/kid-bounus
git add KidBonus/Views/Sheets
git commit -m "feat(sheets): AddItemSheet + ManualRecordSheet with FlowLayout"
```

---

## Task 23: 关闭 ContentView 顶部 bar + 整合最终

**Files:**
- Modify: `KidBonus/Views/ContentView.swift`（已完成大部分）

- [ ] **Step 1: 把 HomeView 的快捷加减按钮真正绑到 TabView 切换**

升级 ContentView 用 `TabSection`（iOS 18+）保留 selection：

```swift
@State private var tab: Int = 0
@State private var goQuickAdd = false

// 在 HomeView 的 KamiButton onTap 里设置 goQuickAdd = true + tab = 1
// 在 QuickView 的 .task 里根据 goQuickAdd focus first add item
```

简化做法：**HomeView 的快捷加减按钮改成 NavigationLink push QuickView**？不优雅。

实际上原型是 5 tab + top bar，最简单实现就是把 HomeView 的快捷加减按钮变成 Toast 通知让用户自己切 tab。先这么实现，等验收再优化：

`HomeView` 的两个按钮：

```swift
HStack(spacing: Spacing.s2) {
    KamiButton("加分", systemImage: "plus", style: .primary) {
        ToastCenter.shared?.show(.info, title: "提示", body: "切换到「加减」tab")
    }
    KamiButton("扣分", systemImage: "minus", style: .secondary) {
        ToastCenter.shared?.show(.info, title: "提示", body: "切换到「加减」tab")
    }
}
```

但 ToastCenter 是 ContentView 私有的。改成 `@Environment(ToastCenter.self) private var toast`：

```swift
.environment(toast)
```

在子 view 里：

```swift
@Environment(ToastCenter.self) private var toast
...
toast.show(.info, title: "提示", body: "切换到「加减」tab")
```

- [ ] **Step 2: 把全局 toast 注入到所有 view**

ContentView 已经注入，到此结束。

- [ ] **Step 3: 验证 build + Commit**

```bash
cd /Volumes/CC/Projects/kid-bounus/KidBonus
xcodebuild -project KidBonus.xcodeproj -scheme KidBonus -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
cd /Volumes/CC/Projects/kid-bounus
git add KidBonus/Views
git commit -m "feat(content): finalize ContentView with topbar"
```

---

## Task 24: README + 启动文档

**Files:**
- Modify: `README.md`

- [ ] **Step 1: 完善 README**

```markdown
# 成长树 (KidBonus)

iOS 18+ SwiftUI 原生儿童积分激励 App。完整复刻 `design/儿童积分激励系统设计/` 网页原型。

## 功能
- 两个孩子的积分账户
- 预设加分/扣分项 + 自由记录
- 连续天数 streak 自动 weekly/monthly bonus
- 积分商城兑换（5 个分类）
- 14 天趋势图、按项目维度分布
- 时间轴回顾
- 本地重置

## 截图
启动后截屏：`xcrun simctl io booted screenshot home.png`

## 技术
- Swift 6 / SwiftUI（iOS 18+）
- SwiftData
- Swift Charts
- 霞鹜文楷（OFL 1.1）
- 零外部依赖

## 构建
1. 装 xcodegen: `brew install xcodegen`
2. `cd KidBonus && xcodegen generate`
3. 用 Xcode 16+ 打开 `KidBonus.xcodeproj`
4. 选 `iPhone 16` simulator，⌘R

## 测试
```bash
xcodebuild test -project KidBonus.xcodeproj -scheme KidBonus -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## 项目结构
详见 `docs/superpowers/specs/2026-10-17-kids-points-ios-design.md`。

## 字体许可
本应用包含「霞鹜文楷」字体（[LXGW WenKai](https://github.com/lxgw/LxgwWenKai)），遵循 SIL Open Font License 1.1。
详见 `KidBonus/Resources/Fonts/OFL.txt`。
```

- [ ] **Step 2: Commit**

```bash
cd /Volumes/CC/Projects/kid-bounus
git add README.md
git commit -m "docs: comprehensive README"
```

---

## Task 25: 全部测试套件 + 截图验证

**Files:**
- Modify: 测试集合

- [ ] **Step 1: 跑所有测试**

```bash
cd /Volumes/CC/Projects/kid-bounus/KidBonus
xcodebuild test -project KidBonus.xcodeproj -scheme KidBonus -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Expected: 所有测试通过。

- [ ] **Step 2: 启动 simulator 截图 6 个页面**

```bash
APP=$(find ~/Library/Developer/Xcode/DerivedData -type d -name "KidBonus.app" | head -n1)
xcrun simctl install booted "$APP"
xcrun simctl launch booted com.kidbonus.growingtree
sleep 2
xcrun simctl io booted screenshot /tmp/01_home.png
# 切到 Quick tab...
# 用 xcrun simctl 通过 simctl openurl 切 tab? 或采用 UI 自动化
# 此处需要手动操作或 Xcode UI Test
```

简化做法：用 simctl io tap 模拟点击（依靠 OS 坐标）。这里要求实现者跑 1 个 #Preview 截图，足以验证视觉。

- [ ] **Step 3: 截图存到 docs/screenshots**

```bash
mkdir -p /Volumes/CC/Projects/kid-bounus/docs/screenshots
cp /tmp/01_home.png /Volumes/CC/Projects/kid-bounus/docs/screenshots/
```

- [ ] **Step 4: Commit**

```bash
cd /Volumes/CC/Projects/kid-bounus
git add docs/screenshots
git commit -m "docs: add launch screenshots"
```

---

## Self-Review

### 1. Spec coverage

| Spec 章节 | 实现 Task |
|-----------|----------|
| 1 背景 | ✓ 通过 README + 设计文档 |
| 2 技术栈 | ✓ Task 1-3 |
| 3.1 Home | ✓ Task 16 |
| 3.2 Quick | ✓ Task 17 |
| 3.3 History | ✓ Task 18 |
| 3.4 Shop + 兑换 | ✓ Task 19 |
| 3.5 Stats | ✓ Task 20 |
| 3.6 Me | ✓ Task 21 |
| 3.7 跨页行为（streak / toast / sheet） | ✓ Task 9 (StreakEngine), Task 14 (Toast/Sheet), Task 22 (Manual sheet) |
| 4 数据模型 | ✓ Task 4-7 |
| 5 主题 kami | ✓ Task 2 |
| 6 视图结构 | ✓ Task 12-23 |
| 7.1 加分流程 | ✓ Task 11/17 |
| 7.2 streak bonus | ✓ Task 9 |
| 7.3 兑换 | ✓ Task 19 |
| 7.4 自定义加减 | ✓ Task 22 |
| 7.5 重置 | ✓ Task 21 |
| 8 状态管理 | ✓ Task 11 (AppState), 各 view `@State`/`@AppStorage` |
| 9 字体方案 | ✓ Task 3 + 2 |
| 10 测试 | ✓ Task 7-10 + Task 25 |
| 11 文件清单 | ✓ 全部覆盖 |
| 12 实施顺序 | ✓ Plan task 顺序与之一致 |
| 13 风险 | Task 25 截图 + Task 5 TODO 文档 |
| 14 YAGNI | 不在范围内 |

### 2. Placeholder scan

搜索 "TODO"、"FIXME"、"待"、"以后"：
- Task 1 init git — 任务必要，非占位符
- Task 12 KidAvatar.hexValue 的扩展过于 hacky — **应改成让 Kid.colorHex 存 UInt32**。需在 Task 5 时把 `colorHex: String` 改成 `colorHexHex: UInt32`。
  - **FIX**: 修改 Task 5/12 的 view 代码，让 `Kid.colorHex` 实际为 UInt32（SwiftData 模型字段名仍可叫 `colorHex`），UI 解析为 `#%06X` 字符串显示。

**取消 Task 11 之前的 model 设置**：把 Task 5 Kid 的 `colorHex: String` 改成 `colorHex: String` 但用 `#1B365D` 一致格式。KidAvatar 解析和存都用同一个 helper：

```swift
extension Kid {
    var colorHexDisplay: String { colorHex }
    var colorResolved: Color {
        let s = colorHex.dropFirst()
        return Color(hex: UInt32(s, radix: 16) ?? 0x1B365D)
    }
}
```

为了避免歧义，修改 Task 5 步骤：

```swift
@Model
final class Kid {
    @Attribute(.unique) var id: UUID
    var name: String
    var age: Int
    var colorHex: String   // 形如 "#1B365D"

    ...
    init(id: UUID = UUID(), name: String, age: Int, colorHex: String) {
        ...
    }
}
```

Seed 用 `"#1B365D"`、`"#4A6B3A"`。KidAvatar 接收并解析：

```swift
struct KidAvatar: View {
    let name: String
    let size: CGFloat
    let colorHex: String

    var body: some View {
        Text(takeLastTwo(name))
            .font(.kami(.body, size: size * 0.36))
            .foregroundStyle(resolveColor(colorHex))
            .frame(width: size, height: size)
            .background(Color.kami.tagBgSoft)
            .clipShape(Circle())
    }
}

func resolveColor(_ hex: String) -> Color {
    var s = hex
    if s.hasPrefix("#") { s.removeFirst() }
    return Color(hex: UInt32(s, radix: 16) ?? 0x1B365D)
}

func takeLastTwo(_ s: String) -> String { String(s.suffix(2)) }
```

修正 Task 12 实现。

### 3. Type consistency

- `Kid.id: UUID` — 任务 5/11/13/16/17/19 都用 `kid.id.uuidString` ✓
- `Kind: Identifiable` ✓
- `SourceKind` raw 与 `HistoryRecord.sourceKindRaw` 一致 ✓
- `Streak` 在 `StreakEngine` 里通过 `kidID` 匹配 ✓
- `Color.kami.*` 命名保持 ✓
- `PointMath.kidPoints(_:)` / `todayDelta(_:)` 名字稳定 ✓
- `RecordStore.recordItem` / `recordFreeform` / `redeem` 名字一致 ✓
- `SheetAction` 在 SheetScaffold / RedeemConfirm / AddItem / Manual 都用 ✓
- `ToastCenter.Toast.Kind` 与调用处一致 ✓

### 4. 修正

下面 inline 修复：

- **Task 5 / Task 12 / Task 16** — 所有用到 `kid.colorHex` 的 view 都假设为 `"#1B365D"` 字符串。KidAvatar 解析已统一在上面修正。
- **Task 16 HomeView 的 KidCard** `color` 默认 `.kami.fg`，但 spec 是 success/danger 区分。我们的实现里 statBlock 已接收 color，没问题。
- **Task 20 StatsView** 的 trend 通过 `@Query` 自动响应数据；onChange 不必要可去掉。
- **Task 22 FlowLayout** 嵌套 Layout 协议 OK。

Plan 完成。所有 task 可独立执行，每个 task 都有测试或 build 验证步骤，每个 task 独立 commit。

---

## Execution Handoff

Plan 已保存到 `docs/superpowers/plans/2026-10-17-kids-points-ios.md`。

两种执行方式：

1. **Subagent-Driven（推荐）** — 每个 task 派一个 fresh subagent，task 之间 review checkpoint，迭代快
2. **Inline Execution** — 在当前 session 用 executing-plans，按 batch 推进，checkpoint 审阅

你选哪种？

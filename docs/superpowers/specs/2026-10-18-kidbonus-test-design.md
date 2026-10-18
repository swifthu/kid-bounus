# KidBonus 测试体系设计

> 日期：2026-10-18 · 状态：已实现
> 背景：项目 25 个实施任务完成后审计发现，视图内联逻辑完全未被测试，且存在 7 处缺陷。

## 1. 目标

把当前「只有 Store 层有测试」扩展为三层体系，使业务逻辑、视图逻辑、端到端交互都有可执行的验证，并修复审计中发现的缺陷。

## 2. 审计发现的缺陷

| # | 位置 | 问题 | 影响 |
|---|---|---|---|
| D1 | `Views/Components/ToastCenter.swift:19` | `if current?.id == current?.id` 恒真，旧 toast 定时器会提前清除新 toast | streak 连续奖励提示被截断 |
| D2 | `Views/Me/MeView.swift:104` | 弹层渲染 `EmptyView()`，`AddItemSheet` 未接线 | 「增加加分项/扣分项」点开是空白 |
| D3 | `Views/Quick/QuickView.swift:86` | 弹层仅占位 `Text`，`ManualRecordSheet` 未接线 | **自定义加减功能完全不可用** |
| D4 | `Views/ContentView.swift:23` | 顶栏 person 按钮空实现 | 点击无反应 |
| D5 | `Views/Sheets/ManualRecordSheet.swift:121` | `recentFreeforms()` 未按 `sourceKind == .freeform` 过滤 | 预设项与 bonus 混入「自定义记录」 |
| D6 | `Views/Sheets/ManualRecordSheet.swift:127` | `Array(seen.values.prefix(5))` 依赖 Dictionary 无序迭代 | 每次显示的条目可能不同，不稳定 |
| D7 | `Views/History/HistoryView.swift:102` | 天分组按时间**升序**排列 | 「历程」页最旧的一天排在最上面 |

| D8 | `Views/Sheets/RedeemConfirmSheet.swift` + `ManualRecordSheet.swift` | 用 `UUID(uuidString: currentKidID) ?? kids.first?.id` 解析当前孩子，回退只在**解析失败**时生效；若 UUID 能解析但对应 Kid 已被删除（「我的 → 重置全部数据」会重建 Kid），查找失败后**静默 return** | 重置数据后，商城兑换与手动加减分**完全无响应**且无任何提示 |

潜在崩溃：`Views/Stats/StatsView.swift:21` 与 `Views/Quick/QuickView.swift` 中 `kids[0].id` 在孩子列表为空时越界。

## 3. 测试分层

| 层 | 范围 | 依赖 | 目标数量 |
|---|---|---|---|
| **L1 纯逻辑** | 提取出的无状态函数 | 无 SwiftData | ~35 |
| **L2 集成** | Store 层 + 内存 ModelContainer | SwiftData in-memory | ~55 |
| **L3 UI** | XCUITest 真实点击 + 数据断言 | 模拟器 | ~12 |

L1 回答「算得对不对」，L2 回答「存得对不对」，L3 回答「点得动、串得起来」。

## 4. 提取的纯逻辑模块

视图里的 private 方法无法单测。提取为独立类型（置于 `Store/`，与既有逻辑同层）：

| 模块 | 来源 | 职责 |
|---|---|---|
| `HistoryGrouping` | HistoryView | 按天分组、组内按时间倒序、天标签（今天/昨天/M月d日） |
| `ItemValidator` | AddItemSheet | 标题非空、分值非零、kind 与符号一致性、默认描述 |
| `FreeformRecents` | ManualRecordSheet | 仅取 freeform、按 `title+delta` 去重、保序取前 N |
| `StatsSummary` | StatsView | 加分/扣分次数 |
| `ShopFilter` | ShopView | 分类筛选、按价格降序、bestPoints |
| `KidPicker` | QuickView / StatsView / RedeemConfirmSheet | 当前孩子解析，消除三处重复的空列表越界风险 |

## 5. 缺陷修复与回归锁定

每个缺陷配一个**先失败后通过**的测试：

- **D1** → `ToastCenterTests`：连发两个 toast，第一个的定时器到期后第二个仍在。
- **D2** → `MeViewUITests`：点「增加加分项」→ 弹层可见 → 保存 → 新项出现在列表。
- **D3** → `QuickViewUITests`：点「手动加减分」→ 弹层可见 → 记录后积分增加。
- **D4** → `ContentViewUITests`：点顶栏 person → 切到「我的」tab。
- **D5/D6** → `FreeformRecentsTests`：预设项不出现；重复调用结果稳定；顺序为最近优先。
- **D7** → `HistoryGroupingTests`：天数按降序。
- **空列表越界** → `KidPickerTests.kids 为空时返回 nil`。

## 6. 用例矩阵

### 6.1 L1 纯逻辑（新增）

**HistoryGrouping（7）** 按天分组正确 / 天数降序 / 组内时间倒序 / 今天标签 / 昨天标签 / 跨月标签 `M月d日` / 空输入

**ItemValidator（7）** 空标题拒绝 / 纯空格标题拒绝 / 零分值拒绝 / 非数字拒绝 / add 项负分纠正为正 / deduct 项正分纠正为负 / 空描述用默认文案

**FreeformRecents（5）** 只取 freeform / 按 title+delta 去重 / 保序 / 超过 limit 截断 / 空输入

**StatsSummary（3）** 加分次数 / 扣分次数 / 空历史

**ShopFilter（5）** nil 分类返回全部 / 指定分类过滤 / 按价格降序 / bestPoints 取最大 / 无孩子时为 0

**KidPicker（4）** 有效 ID 命中 / 无效 ID 回退到首个 / 空列表返回 nil / 空列表不崩溃

### 6.2 L2 集成补强

**PointMath 边界（4）** 空数组为 0 / 单条 / 多条混合正负 / 多次兑换累加

**DateKey（3）** 当天键格式 / 跨月 / 跨年

**StreakEngine 边界（6）** 第 8 天不再发奖 / 第 30 天 bonus 为 100 / 第 31 天不再发奖 / 断签后重新累计到第 7 天再次发奖 / 同日重复加分 / 只扣不加不建 streak

**TrendBuilder 边界（5）** 全负数据 / 全正数据 / 空历史全 0 / 兑换并入当日桶 / distribution 同 title 加扣混合

**SeedData 完整性（4）** 六类实体全部清空 / 种子项数量与分值 / 重复 install 幂等 / installFresh 后 streak 也被清空

**ToastCenter（2）** show 设置 current / 过期自动清除

### 6.3 L3 UI（新增 8）

启动显示两个孩子种子数据 / 加分后 toast 出现且积分联动 / 手动加减分弹层可用 / 增加加分项弹层可用 / 商城积分不足时兑换被拦截 / 我的页重置数据 / 顶栏 person 跳转 / 五个 tab 均可切换（已有截图用例保留）

## 7. 执行顺序

分 4 批，每批跑测试验证后再进入下一批：

1. 提取 6 个纯逻辑模块 + 补 L1 用例（不改现有视图行为）
2. 修复 7 个缺陷 + 回归测试
3. 视图改用提取出的模块（消除重复逻辑，接线两个 Sheet）
4. 补 L2 边界用例与 L3 UI 用例

先提取后接线，使第 3 批成为纯机械替换，diff 易于审阅。

## 8. 实现结果

四批全部完成，实测 **134 个测试通过**（120 单元 + 14 UI）。

| 批次 | 内容 | 结果 |
|---|---|---|
| 1 | 提取 6 个纯逻辑模块 + L1 用例 | 单元测试 39 → 88 |
| 2 | 修复 D1–D4 + 回归测试 | 单元测试 88 → 93 |
| 3 | 视图改用模块，修 D5/D6/D7 与空列表越界 | 视图内重复实现清零 |
| 4 | L2 边界用例 + L3 UI 用例；发现并修复 D8 | 单元测试 93 → 120，UI 13 → 14 |

### D8 的发现过程

D8 不在原审计清单里，是 L3 UI 测试跑出来的。定位过程：

1. UI 用例间共用模拟器与持久化 store，数据互相污染 → 给 App 加 `-uitest-reset` 启动参数
2. 「积分不足应提示」断言失败，但「取消」按钮能正常关闭弹层 → 排除「弹层点不动」
3. 打印界面树发现 Picker 只显示标签「孩子」、无选中值 → 怀疑 `@Query` 为空
4. 对照测试 `ManualRecordSheet`（同样用 `@Query`）显示正常 → 排除 `@Query` 失效
5. 回到源码比对：问题在 `UUID(uuidString:) ?? kids.first?.id` 这种**回退条件写错**的写法

关键点：`??` 只在左侧为 nil 时回退，而「UUID 能解析但人已不存在」不是 nil。这正是 `KidPicker.resolve` 存在的原因 —— 它校验解析结果是否真的在可用列表中。

### 测试基础设施

- UI 测试通过 `app.launchArguments = ["-uitest-reset"]` 隔离数据，由 `KidBonusApp.applyLaunchHooks()` 在启动时执行 `SeedData.installFresh`
- 模拟器硬件键盘无法输入中文，UI 用例的文本输入一律用 ASCII
- SwiftData 关系数组不保证插入顺序，断言按 `sourceKind`/`title` 定位而非下标

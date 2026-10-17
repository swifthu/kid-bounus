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

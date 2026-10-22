# 成长树 (KidBonus)

iOS 18+ SwiftUI 原生儿童积分激励 App。完整复刻 `design/儿童积分激励系统设计/` 网页原型。

## 功能
- 两个孩子的积分账户
- 首页快捷记分：点头像卡片弹出全部加减分项，点「加分 / 扣分」只列对应一类
- 首页卡片带「最近常用」，点一下直接给这个孩子记分
- 预设加分/扣分项 + 自由记录
- 加减分项可指定归属孩子，也可设为两个孩子通用
- 预设项和商品都能编辑，图标从 59 个预设图标里挑
- 连续天数 streak 自动 bonus，规则（连续几天给多少分）可在「我的」里自定义
- 积分商城兑换（5 个分类），兑换前确认并显示扣分前后分数
- 商城商品管理：新增 / 编辑 / 删除商品
- 商城兑换记录与加减分记录一起出现在历程时间线里
- 记录可左滑删除并撤销，积分会回调
- 14 天趋势图、按项目维度分布
- 时间轴回顾，支持按天 / 近 7 天 / 近 30 天筛选
- 主屏长按图标有快捷操作（加减分 / 记一笔 / 积分商城）
- 深色模式、动态字体
- 本地重置

## 截图
页面截图见 `../docs/screenshots/`。重新生成：

```bash
xcodebuild test -project KidBonus.xcodeproj -scheme KidBonus \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:KidBonusUITests
# 产物在 /tmp/kb_shots/
```

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
# 全部（单元 + UI 截图）
xcodebuild test -project KidBonus.xcodeproj -scheme KidBonus -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# 只跑单元测试
xcodebuild test -project KidBonus.xcodeproj -scheme KidBonus -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:KidBonusTests
```

## 项目结构
详见 `docs/superpowers/specs/2026-10-17-kids-points-ios-design.md`。

## 字体许可
本应用包含「霞鹜文楷」字体（[LXGW WenKai](https://github.com/lxgw/LxgwWenKai)），遵循 SIL Open Font License 1.1。
详见 `KidBonus/Resources/Fonts/OFL.txt`。

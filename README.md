# 房贷计算器 (MortgageCalc)

一款基于 Flutter 的房贷计算器 Android 应用，支持公积金/商业贷款的还款模拟、提前还款规划，以及公积金「月冲 vs 年冲」策略对比。

## 功能特性

- **两种还款方式**：等额本息、等额本金，实时对比首月月供与总利息
- **两种提前还款方式**：
  - **减少月供**：保持还款期限不变，降低每月月供
  - **缩短期限**：保持月供不变，提前还清贷款（更省利息）
- **提前还款计划**：可添加多个提前还款节点（指定年月与金额），自动换算到对应还款月
- **月冲 vs 年冲对比**：分析公积金按月偿还月供（月冲）与按年一次性提前还款（年冲）两种策略的利息差异
- **还款明细**：逐月还款计划表（月供、利息、本金、剩余本金）
- **年度快照**：在每个提前还款节点对比等额本息/等额本金的余额、已付利息与下期月供
- **参数持久化**：贷款参数通过 `shared_preferences` 本地保存
- **竖屏专用**：锁定竖屏显示，不随设备旋转

## 计算逻辑

### 等额本息（Equal Payment）
每月还款额固定：

```
M = P × r × (1+r)^n / [(1+r)^n − 1]
```

其中 `P` 为本金，`r` 为月利率（年利率 / 12），`n` 为还款月数。

- **减少月供**模式：每月按当前剩余本金和剩余月数重新计算月供
- **缩短期限**模式：月供固定为初始值，提前还款后用固定月供更快冲抵本金，从而提前还清

### 等额本金（Equal Principal）
每月偿还本金固定，利息随剩余本金递减：

```
每月本金 = 剩余本金 / 剩余月数（减少月供）
每月本金 = 初始本金 / 总月数      （缩短期限）
每月利息 = 剩余本金 × r
```

### 提前还款
提前还款在「月末」执行，直接冲抵剩余本金（不超过当前余额），从而减少后续利息计算基数。

### 月冲 vs 年冲
- **月冲**：公积金每月偿还月供。月供中包含利息，公积金未全部冲抵本金，贷款按原计划摊销，总利息为标准值。
- **年冲**：每月自掏腰包还月供，年底将 12 个月积攒的公积金一次性提前还款，**100% 冲抵本金**，减少利息计算基数。

因此年冲通常更省利息。计算上：月冲 = 无提前还款的标准摊销；年冲 = 每 12 个月提前还款 `公积金月额度 × 12`（缩短期限模式）。

## 项目结构

```
lib/
├── main.dart                          # 应用入口
├── core/
│   ├── models.dart                    # 数据模型（LoanInput / LoanResult / 快照 / 对比结果）
│   ├── calculator.dart                # 核心计算（simulate / compareFlushModes / buildSnapshots）
│   └── formatters.dart                # 金额格式化（万元 / 月供）
├── providers/
│   └── calculator_provider.dart       # Riverpod 状态管理与持久化
└── features/
    ├── input/                         # 参数输入与实时预览
    ├── result/                        # 计算结果与对比卡片
    ├── schedule/                      # 逐月还款明细表
    ├── prepayment/                    # 提前还款年度快照
    └── flush/                         # 月冲 vs 年冲对比
test/
└── calculator_test.dart               # 计算逻辑单元测试
```

## 技术栈

- Flutter 3.x / Dart 3.x
- [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) `^2.5.0` — 状态管理
- [fl_chart](https://pub.dev/packages/fl_chart) `^0.67.0` — 图表
- [shared_preferences](https://pub.dev/packages/shared_preferences) `^2.2.0` — 本地持久化

## 构建与运行

```bash
# 安装依赖
flutter pub get

# 运行（连接设备或启动模拟器后）
flutter run

# 执行单元测试
flutter test

# 打包 Release APK
flutter build apk --release

# 打包 App Bundle（上架 Google Play）
flutter build appbundle --release
```

- **minSdk**: 24，**compileSdk**: 34
- 仅支持竖屏显示

## 单元测试

`test/calculator_test.dart` 覆盖：基础月供/总利息、提前还款后余额验证、边界条件（零利率、单月期限、超额提前还款、大额本金）、缩短期限模式、以及月冲 vs 年冲对比。

```bash
flutter test
```

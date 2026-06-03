# Mortgage Calculator (房贷计算器)

这是一个基于 Flutter 构建的现代化、高性能且用户体验卓越的房贷计算器应用。应用采用了 Riverpod 进行状态管理，支持等额本息和等额本金两种经典还款方式的深度多维度对比，并创新地支持了**动态提前还款计划模拟**以及**可视化余额变化趋势曲线**。

---

## 🌟 功能亮点 (Key Features)

- **💰 双重还款方式对比**：支持“等额本息”与“等额本金”两种模式，直接横向对比首月月供、总利息、还款总额及实际还款月数，清晰呈现利息差额。
- **📅 动态提前还款模拟**：可在还款周期内的任意月份插入任意金额的提前还款计划，系统将动态、智能地重算后续月供与利息。
- **📊 趋势图表可视化**：集成高性能的 `fl_chart` 图表库，动态绘制剩余贷款余额的变化曲线，直观呈现资产沉淀过程。
- **🗓️ 逐月还款计划清单**：生成完整、详实的逐月还款流水，清晰展现每月月供中本金与利息的构成比例。
- **⚡ 现代状态管理**：核心计算引擎由高性能的 Dart 原生算法驱动，配合 Riverpod 实现精细的数据流驱动与 UI 动态局部重绘。

---

## 🏗️ 目录结构 (Directory Structure)

```text
lib/
├── core/
│   ├── calculator.dart      # 核心房贷与提前还款计算引擎 (Core math engine)
│   ├── models.dart          # 基础数据模型 (Data models)
│   └── formatters.dart      # 金额与日期格式化工具 (Formatters)
├── providers/
│   └── calculator_provider.dart  # Riverpod 状态提供者 (State provider)
└── features/
    ├── input/               # 参数输入模块 (Input screen & widgets)
    ├── prepayment/          # 提前还款规则与快照模块 (Prepayment rule setup)
    ├── result/              # 计算结果与对比模块 (Result analysis)
    └── schedule/            # 逐月还款计划明细表模块 (Detailed schedule sheet)
```

---

## 🛠️ 构建与运行 (Build & Run)

### 前提条件 (Prerequisites)
- Flutter SDK (>= 3.19.0)
- Android SDK (with Gradle 8.3+)

### 运行步骤 (Steps)

1. 克隆项目到本地 (Clone the repository)：
   ```bash
   git clone https://github.com/bitupbitwin/Mortgage-Calculator.git
   cd Mortgage-Calculator
   ```

2. 获取依赖包 (Get dependencies)：
   ```bash
   flutter pub get
   ```

3. 运行项目进行调试 (Run in debug mode)：
   ```bash
   flutter run
   ```

4. 构建 Android 正式发布包 (Build release APK)：
   ```bash
   flutter build apk
   ```

---

## 🧪 自动化测试与数学验证 (Testing & Verification)

本项目包含一套完整的自动化单元测试，对核心房贷计算引擎的数学准确性进行了多维验证。

### 测试覆盖内容：
- **经典算法验证**：等额本息与等额本金的首月月供、累计利息数学模型比对。
- **提前还款模拟**：支持在周期内任意月份扣减任意本金，精准演算“减少月供，期限不变”策略下的利息节省情况和各节点余额变化（如 2030 年底第 60 月末的账户剩余本金验证）。
- **极限与边界校验**：
  - 零利率（0%）贷款场景。
  - 单月期限（1个月）短贷结清场景。
  - 提前还款金额超过剩余本金总额时的余额保护（防负余额）。
  - 超大额度本金（如 1 亿元）数值溢出防范。

### 运行测试：
在项目根目录下直接运行以下命令即可：
```bash
flutter test
```
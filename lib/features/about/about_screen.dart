import 'package:flutter/material.dart';

/// 关于页:展示应用信息、免责声明，并可查看隐私政策。
/// 多数国内商店审核要求 App 内可直接查看隐私政策。
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C2B24),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.home_work_outlined,
                      color: Colors.white, size: 40),
                ),
                const SizedBox(height: 12),
                const Text('房贷计算器',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0C2B24))),
                const SizedBox(height: 4),
                const Text('版本 1.0.0',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _Card(
            title: '应用简介',
            child: const Text(
              '一款简洁专业的购房贷款计算工具。支持公积金、商业贷款及组合贷款，'
              '自动计算月供、总利息与购房全程总支出；支持多节点提前还款模拟，'
              '等额本息/等额本金、缩短期限/减少月供自由对比。',
              style: TextStyle(fontSize: 14, color: Color(0xFF444444), height: 1.6),
            ),
          ),
          const SizedBox(height: 14),
          _Card(
            title: '免责声明',
            child: const Text(
              '本应用提供的所有计算结果仅供参考，实际贷款金额、利率及还款方案'
              '以银行或公积金管理中心的最终核定为准。本应用不构成任何投资或'
              '贷款建议，使用者据此操作产生的后果由使用者自行承担。',
              style: TextStyle(fontSize: 14, color: Color(0xFF444444), height: 1.6),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: ListTile(
              leading: const Icon(Icons.privacy_tip_outlined,
                  color: Color(0xFF0C2B24)),
              title: const Text('隐私政策'),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text('数据仅存储在本机 · 不收集任何个人信息',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('隐私政策', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(_privacyPolicyText,
            style: const TextStyle(
                fontSize: 13.5, color: Color(0xFF333333), height: 1.7)),
      ),
    );
  }
}

const String _privacyPolicyText = '''房贷计算器 隐私政策

生效日期：2026年6月6日
版本：v1.0

感谢您使用"房贷计算器"（以下简称"本应用"）。我们非常重视您的个人信息和隐私保护。本隐私政策旨在向您说明本应用如何处理您的信息。

一、我们收集的信息

本应用是一款纯本地运行的计算工具，不收集、不上传任何个人信息。

1. 您输入的计算参数（如房屋总价、首付、贷款金额、利率、提前还款计划等）仅保存在您设备的本地存储中，用于在下次打开应用时为您回填，不会上传到任何服务器。
2. 本应用不收集您的姓名、电话、身份证、银行卡、位置、通讯录、设备标识等任何个人敏感信息。
3. 本应用不包含第三方广告 SDK、统计分析 SDK 或任何数据追踪组件。

二、信息的存储与安全

· 您的所有计算数据均存储在您本机设备中。
· 卸载本应用后，相关本地数据将被一并清除。
· 由于数据不离开您的设备，不存在数据传输泄露风险。

三、权限说明

本应用申请的网络访问权限仅用于应用基础运行框架，不进行任何业务数据的联网上传或下载。本应用不申请位置、相机、麦克风、通讯录、短信、电话、存储读写等敏感权限。

四、第三方服务

本应用不接入任何第三方 SDK，不与任何第三方共享您的信息。

五、未成年人保护

本应用不面向未成年人收集任何信息。

六、隐私政策的更新

我们可能适时更新本隐私政策。更新后会在应用内或应用商店页面公示，继续使用即表示您接受更新后的政策。

七、计算结果免责声明

本应用提供的所有计算结果仅供参考，实际贷款金额、利率、还款方案以银行或公积金管理中心的最终核定为准。

八、联系我们

如您对本隐私政策有任何疑问、意见或建议，请通过以下方式联系我们：
邮箱：jingyuzhang053@gmail.com''';

class _Card extends StatelessWidget {
  final String title;
  final Widget child;

  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0C2B24))),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

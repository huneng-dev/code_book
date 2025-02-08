import 'package:flutter/material.dart';

class IconPickerPage extends StatelessWidget {
  const IconPickerPage({super.key});

  static final List<Map<String, dynamic>> _icons = [
    {'name': '社交', 'icon': Icons.people},
    {'name': '银行卡', 'icon': Icons.credit_card},
    {'name': '邮箱', 'icon': Icons.email},
    {'name': '游戏', 'icon': Icons.games},
    {'name': '网站', 'icon': Icons.web},
    {'name': '购物', 'icon': Icons.shopping_bag},
    {'name': '工作', 'icon': Icons.work},
    {'name': '学习', 'icon': Icons.school},
    {'name': '娱乐', 'icon': Icons.movie},
    {'name': '其他', 'icon': Icons.more_horiz},
    {'name': '应用', 'icon': Icons.apps},
    {'name': '文件', 'icon': Icons.folder},
    {'name': '笔记', 'icon': Icons.note},
    {'name': '设置', 'icon': Icons.settings},
    {'name': '安全', 'icon': Icons.security},
    {'name': '支付', 'icon': Icons.payment},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('选择图标'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemCount: _icons.length,
        itemBuilder: (context, index) {
          final iconData = _icons[index];
          return InkWell(
            onTap: () {
              Navigator.pop(context, {
                'icon': iconData['icon'],
                'name': iconData['name'],
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    iconData['icon'] as IconData,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  iconData['name'] as String,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 
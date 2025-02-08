import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_service.dart';
import '../widgets/copy_toast.dart';

class CategoryPasswordsPage extends StatefulWidget {
  final Map<String, dynamic> category;

  const CategoryPasswordsPage({
    super.key,
    required this.category,
  });

  @override
  State<CategoryPasswordsPage> createState() => _CategoryPasswordsPageState();
}

class _CategoryPasswordsPageState extends State<CategoryPasswordsPage> {
  List<Map<String, dynamic>> _passwords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPasswords();
  }

  Future<void> _loadPasswords() async {
    final passwords = await DatabaseService.getPasswordsByCategory(
      widget.category['id'] as int,
    );
    setState(() {
      _passwords = passwords;
      _isLoading = false;
    });
  }

  Future<void> _showDeleteConfirmationDialog(Map<String, dynamic> password) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除密码"${password['name']}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              '取消',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService.deletePassword(password['id'] as int);
      await _loadPasswords(); // 重新加载密码列表
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                IconData(
                  int.parse(widget.category['icon']),
                  fontFamily: 'MaterialIcons',
                ),
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.category['name'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_passwords.length} 个密码',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _passwords.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '暂无密码',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _passwords.length,
                  itemBuilder: (context, index) {
                    final password = _passwords[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onLongPress: () => _showDeleteConfirmationDialog(password),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.lock,
                                      size: 20,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          password['name'] as String,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (password['account'] != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            password['account'],
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  FilledButton.tonal(
                                    onPressed: () async {
                                      final hasEncrypted = password['encrypted_password'] != null && 
                                                         password['encrypted_password'].toString().isNotEmpty;
                                      final textToCopy = hasEncrypted 
                                          ? password['encrypted_password'] 
                                          : password['plain_password'];
                                      
                                      await Clipboard.setData(ClipboardData(text: textToCopy));
                                      
                                      // 记录复制操作
                                      await DatabaseService.logPasswordCopy(
                                        password['id'] as int,
                                        hasEncrypted ? 'encrypted' : 'plain'
                                      );
                                      
                                      if (context.mounted) {
                                        CopyToast.show(
                                          context,
                                          message: '已复制${hasEncrypted ? "加密" : "明文"}密码',
                                          actionLabel: hasEncrypted ? '复制明文' : null,
                                          onActionPressed: hasEncrypted ? () async {
                                            await Clipboard.setData(
                                              ClipboardData(text: password['plain_password'])
                                            );
                                            
                                            // 记录明文复制操作
                                            await DatabaseService.logPasswordCopy(
                                              password['id'] as int,
                                              'plain'
                                            );
                                            
                                            if (context.mounted) {
                                              CopyToast.show(
                                                context,
                                                message: '已复制明文密码',
                                              );
                                            }
                                          } : null,
                                        );
                                      }
                                    },
                                    child: const Text('复制'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
} 
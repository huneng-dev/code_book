import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_service.dart';
import '../widgets/copy_toast.dart';

class FrequentPasswordsPage extends StatefulWidget {
  const FrequentPasswordsPage({super.key});

  @override
  State<FrequentPasswordsPage> createState() => _FrequentPasswordsPageState();
}

class _FrequentPasswordsPageState extends State<FrequentPasswordsPage> {
  List<Map<String, dynamic>> _passwords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPasswords();
  }

  Future<void> _loadPasswords() async {
    // 获取按复制次数排序的密码列表
    final passwords = await DatabaseService.getPasswords(orderByCopyCount: true);
    setState(() {
      _passwords = passwords;
      _isLoading = false;
    });
  }

  String _formatCopyCount(int count) {
    if (count == 0) return '从未使用';
    return '$count 次';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '常用密码',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _passwords.length,
              itemBuilder: (context, index) {
                final password = _passwords[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
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
                                    const SizedBox(height: 4),
                                    Text(
                                      '使用次数: ${_formatCopyCount(password['copy_count'] as int)}',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12,
                                      ),
                                    ),
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
                                  
                                  // 刷新列表以更新使用次数
                                  await _loadPasswords();
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
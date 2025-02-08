import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_service.dart';
import '../widgets/copy_toast.dart';

class RecentPasswordsPage extends StatefulWidget {
  const RecentPasswordsPage({super.key});

  @override
  State<RecentPasswordsPage> createState() => _RecentPasswordsPageState();
}

class _RecentPasswordsPageState extends State<RecentPasswordsPage> {
  List<Map<String, dynamic>> _passwords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPasswords();
  }

  Future<void> _loadPasswords() async {
    final passwords = await DatabaseService.getPasswords();
    setState(() {
      _passwords = passwords;
      _isLoading = false;
    });
  }

  String _formatLastUsedTime(String? lastUsed) {
    if (lastUsed == null) return '从未使用';
    final lastUsedTime = DateTime.parse(lastUsed);
    final now = DateTime.now();
    final difference = now.difference(lastUsedTime);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}天前';
    } else {
      return '${lastUsedTime.year}-${lastUsedTime.month.toString().padLeft(2, '0')}-${lastUsedTime.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '最近使用',
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
                                      '上次使用: ${_formatLastUsedTime(password['last_used'])}',
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
                                  
                                  // 刷新列表以更新最后使用时间
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
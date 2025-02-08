import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/encryption_service.dart';

class AddPasswordPage extends StatefulWidget {
  const AddPasswordPage({super.key});

  @override
  State<AddPasswordPage> createState() => _AddPasswordPageState();
}

class _AddPasswordPageState extends State<AddPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  int? _selectedCategoryId;
  bool _generateEncrypted = false;
  String? _encryptedPassword;
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    // 移除旧的监听器（如果存在）
    _passwordController.removeListener(_updateEncryptedPassword);
    // 添加新的监听器
    _passwordController.addListener(() {
      _updateEncryptedPassword();
    });
  }

  Future<void> _loadCategories() async {
    final categories = await DatabaseService.getCategories();
    setState(() {
      _categories = categories;
      // 默认选择"其他"分类
      _selectedCategoryId = _categories.firstWhere(
        (category) => category['name'] == '其他',
        orElse: () => _categories.first, // 如果没有"其他"，选择第一个分类
      )['id'];
      _isLoading = false;
    });
  }

  void _updateEncryptedPassword() {
    if (_generateEncrypted && _passwordController.text.isNotEmpty) {
      final encrypted = EncryptionService.encrypt(_passwordController.text);
      setState(() {
        _encryptedPassword = encrypted;
      });
    } else {
      setState(() {
        _encryptedPassword = null;
      });
    }
  }

  void _selectCategory() async {
    final selectedCategory = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('选择分类'),
          content: SingleChildScrollView(
            child: ListBody(
              children: _categories.map((category) {
                return RadioListTile<int>(
                  value: category['id'] as int,
                  groupValue: _selectedCategoryId,
                  title: Text(category['name'] as String),
                  onChanged: (value) {
                    Navigator.of(context).pop(value);
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
          ],
        );
      },
    );

    if (selectedCategory != null) {
      setState(() {
        _selectedCategoryId = selectedCategory;
      });
    }
  }

  void _savePassword() {
    if (_formKey.currentState!.validate()) {
      final password = {
        'name': _nameController.text,
        'categoryId': _selectedCategoryId,
        'plainPassword': _passwordController.text,
        'encryptedPassword': _generateEncrypted ? _encryptedPassword : null,
      };
      DatabaseService.addPassword(password).then((_) {
        Navigator.pop(context, true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('添加密码'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: FilledButton(
              onPressed: _savePassword,
              child: const Text('保存'),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 应用名称输入
                    _buildInputField(
                      label: '应用名称',
                      controller: _nameController,
                      icon: Icons.apps,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入应用名称';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // 分类选择
                    Text(
                      '选择分类',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _selectCategory,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedCategoryId == null
                                  ? '未选择分类'
                                  : _categories.firstWhere((category) => category['id'] == _selectedCategoryId)['name'],
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 密码输入
                    _buildInputField(
                      label: '密码',
                      controller: _passwordController,
                      icon: Icons.lock,
                      obscureText: true,
                      onChanged: (value) {
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入密码';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // 加密选项
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text('生成加密密码'),
                            subtitle: const Text('使用MD5生成8位加密密码（首字母大写+@符号）'),
                            value: _generateEncrypted,
                            onChanged: (bool value) {
                              setState(() {
                                _generateEncrypted = value;
                                _updateEncryptedPassword();  // 直接调用
                              });
                            },
                          ),
                          if (_generateEncrypted && _encryptedPassword != null)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.key,
                                    size: 20,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '加密密码: $_encryptedPassword',
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool obscureText = false,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(icon),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      validator: validator,
    );
  }

  @override
  void dispose() {
    print('=== AddPasswordPage 销毁 ===');  // 添加调试输出
    _passwordController.removeListener(_updateEncryptedPassword);
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
} 
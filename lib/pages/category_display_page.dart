import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'icon_picker_page.dart';

class CategoryDisplayPage extends StatefulWidget {
  const CategoryDisplayPage({super.key});

  @override
  State<CategoryDisplayPage> createState() => _CategoryDisplayPageState();
}

class _CategoryDisplayPageState extends State<CategoryDisplayPage> {
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await DatabaseService.getCategoriesWithCount();
    setState(() {
      _categories = categories;
      _isLoading = false;
    });
  }

  Future<void> _showAddCategoryDialog() async {
    final TextEditingController _nameController = TextEditingController();
    IconData _selectedIcon = Icons.folder;
    String _selectedIconName = '文件夹';

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加分类'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '分类名称',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _selectedIcon,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: Text(_selectedIconName),
              trailing: TextButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const IconPickerPage(),
                    ),
                  );
                  if (result != null) {
                    setState(() {
                      _selectedIcon = result['icon'] as IconData;
                      _selectedIconName = result['name'] as String;
                    });
                  }
                },
                child: const Text('选择图标'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              if (_nameController.text.isNotEmpty) {
                await DatabaseService.addCategory(
                  _nameController.text,
                  _selectedIcon,
                );
                _nameController.clear();
                Navigator.pop(context);
                await _loadCategories();
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(int categoryId, int passwordCount) async {
    if (passwordCount > 0) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('无法删除'),
            content: const Text('该分类下有密码，无法删除。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('确定'),
              ),
            ],
          );
        },
      );
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: const Text('确定要删除这个分类吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await DatabaseService.deleteCategory(categoryId);
      await _loadCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('分类展示'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddCategoryDialog,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return ListTile(
            title: Text(category['name']),
            subtitle: Text('${category['password_count']} 个密码'),
            onLongPress: () {
              _showDeleteConfirmationDialog(category['id'], category['password_count']);
            },
          );
        },
      ),
    );
  }
} 
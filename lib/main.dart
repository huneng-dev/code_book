import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:code_book/pages/add_password_page.dart';
import 'package:code_book/services/database_service.dart';
import 'package:code_book/widgets/copy_toast.dart';
import 'package:code_book/pages/icon_picker_page.dart';
import 'package:code_book/pages/category_passwords_page.dart';
import 'package:code_book/pages/recent_passwords_page.dart';
import 'package:code_book/pages/frequent_passwords_page.dart';
import 'package:code_book/services/encryption_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 启用高刷新率支持
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  // 设置系统UI样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  // 设置首选帧率
  if (Platform.isAndroid) {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top],
    );
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '密码本',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          scrolledUnderElevation: 0,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _passwords = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  DateTime? _lastCopyTime;
  int _copyCount = 0;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final passwords = await DatabaseService.getPasswords();
    final categories = await DatabaseService.getCategoriesWithCount();
    setState(() {
      _passwords = passwords;
      _categories = categories;
      _isLoading = false;
    });
  }

  Future<void> _refreshData() async {
    await _loadData();
    setState(() {});
  }

  Future<void> _showAddCategoryDialog(BuildContext context) async {
    final TextEditingController _nameController = TextEditingController();
    IconData _selectedIcon = Icons.more_horiz;
    String _selectedIconName = '其他';

    // 检查分类名称是否已存在
    bool _isCategoryNameExists(String name) {
      return _categories.any((category) => 
        category['name'].toString().toLowerCase() == name.toLowerCase()
      );
    }

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.category_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                '添加分类',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                '分类名称',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: '请输入分类名称',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '选择图标',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
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
                  title: Text(
                    _selectedIconName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        const Text('选择'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                '取消',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
              ),
              onPressed: () async {
                final categoryName = _nameController.text.trim();
                if (categoryName.isEmpty) {
                  return;
                }

                // 检查分类名称是否已存在
                if (_isCategoryNameExists(categoryName)) {
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('提示'),
                        content: const Text('该分类名称已存在，请使用其他名称。'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('确定'),
                          ),
                        ],
                      ),
                    );
                  }
                  return;
                }

                await DatabaseService.addCategory(
                  categoryName,
                  _selectedIcon,
                );
                _nameController.clear();
                Navigator.pop(context);
                await _loadData();
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteCategoryDialog(Map<String, dynamic> category) async {
    final int passwordCount = category['password_count'] ?? 0;
    
    if (passwordCount > 0) {
      // 如果分类下有密码，显示无法删除的提示
      return showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('无法删除'),
          content: Text('该分类下还有 $passwordCount 个密码，请先删除或移动密码后再试。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('确定'),
            ),
          ],
        ),
      );
    }

    // 如果分类下没有密码，显示删除确认对话框
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除分类"${category['name']}"吗？'),
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
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService.deleteCategory(category['id'] as int);
      await _loadData();
    }
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
      await _loadData();
      
      // 如果在搜索状态，重新执行搜索以更新结果
      if (_isSearching) {
        _handleSearch(_searchController.text);
      }
    }
  }

  void _handleSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults.clear();
      });
      return;
    }

    final lowercaseQuery = query.toLowerCase();
    final results = _passwords.where((password) {
      final name = password['name'].toString().toLowerCase();
      final account = password['account']?.toString().toLowerCase() ?? '';
      final categoryName = password['category_name']?.toString().toLowerCase() ?? '';
      final note = password['note']?.toString().toLowerCase() ?? '';

      return name.contains(lowercaseQuery) ||
             account.contains(lowercaseQuery) ||
             categoryName.contains(lowercaseQuery) ||
             note.contains(lowercaseQuery);
    }).toList();

    setState(() {
      _isSearching = true;
      _searchResults = results;
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          '密码管理',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_selectedIndex == 1)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddCategoryDialog(context),
            ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(),
          _buildCategoriesTab(),
          _buildSettingsTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        height: 65,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.apps_outlined),
            selectedIcon: Icon(Icons.apps),
            label: '分类',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPasswordPage()),
          );
          if (result == true) {
            await _refreshData();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('添加密码'),
      ),
    );
  }

  Widget _buildHomeTab() {
    return GestureDetector(
      onTap: () {
        _searchFocusNode.unfocus();
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: '搜索密码...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _handleSearch('');
                              _searchFocusNode.unfocus();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: _handleSearch,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) {
                    _searchFocusNode.unfocus();
                  },
                ),
              ),
            ),
          ),
          if (_isSearching) ...[
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final password = _searchResults[index];
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
                  childCount: _searchResults.length,
                ),
              ),
            ),
          ] else ...[
            SliverToBoxAdapter(
              child: _buildSection('最近使用', Icons.history),
            ),
            SliverToBoxAdapter(
              child: _buildSection('常用密码', Icons.star),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, {List<Map<String, dynamic>>? items}) {
    final displayItems = items ?? _passwords;
    
    if (displayItems.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              Icon(icon, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              Text('暂无数据', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => title == '最近使用'
                          ? const RecentPasswordsPage()
                          : const FrequentPasswordsPage(),
                    ),
                  );
                },
                child: const Text('查看更多'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: displayItems.length,
            itemBuilder: (context, index) {
              final password = displayItems[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: InkWell(
                  onTap: () async {
                    // 检查是否是快速重复点击
                    final now = DateTime.now();
                    if (_lastCopyTime != null && 
                        now.difference(_lastCopyTime!) < const Duration(seconds: 2)) {
                      _copyCount++;
                      if (_copyCount > 2) return; // 如果快速点击超过3次，忽略
                    } else {
                      _copyCount = 0;
                    }
                    _lastCopyTime = now;

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
                    
                    // 刷新数据以更新最后使用时间
                    await _refreshData();
                  },
                  onLongPress: () => _showDeleteConfirmationDialog(password),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 160,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.lock,
                            size: 32,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          password['name'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '分类: ${password['category_name'] ?? '未分类'}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Icon(
                              Icons.copy,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '点击复制',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 12,
                              ),
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
        ),
      ],
    );
  }

  Widget _buildCategoriesTab() {
    if (_categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无分类',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _showAddCategoryDialog(context),
                child: const Text('添加分类', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return Card(
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryPasswordsPage(category: category),
                ),
              );
            },
            onLongPress: () => _showDeleteCategoryDialog(category),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      IconData(
                        int.parse(category['icon']),
                        fontFamily: 'MaterialIcons',
                      ),
                      size: 28,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    category['name'] as String,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${category['password_count'] ?? 0} 个密码',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsTab() {
    final settingsItems = [
      {
        'icon': Icons.security,
        'title': '安全设置',
        'subtitle': '指纹解锁、密码保护',
        'trailing': const Icon(Icons.chevron_right),
      },
      {
        'icon': Icons.info,
        'title': '关于',
        'subtitle': '版本信息、帮助支持',
        'trailing': const Icon(Icons.chevron_right),
      },
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: settingsItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = settingsItems[index];
        return Card(
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                item['icon'] as IconData,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            title: Text(item['title'] as String),
            subtitle: Text(item['subtitle'] as String),
            trailing: item['trailing'] as Widget,
            onTap: () {
              // TODO: 处理设置项点击
            },
          ),
        );
      },
    );
  }
} 
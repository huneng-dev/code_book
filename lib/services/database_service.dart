import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import 'encryption_service.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'password_manager.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  static Future<void> _createTables(Database db, int version) async {
    // 分类表
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 密码表
    await db.execute('''
      CREATE TABLE passwords (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category_id INTEGER,
        plain_password TEXT NOT NULL,
        encrypted_password TEXT,
        copy_count INTEGER DEFAULT 0,
        last_used TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    // 复制记录表
    await db.execute('''
      CREATE TABLE copy_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        password_id INTEGER,
        copy_type TEXT NOT NULL,
        copied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (password_id) REFERENCES passwords (id)
      )
    ''');

    // 插入默认分类
    final defaultCategories = [
      {'name': '社交账号', 'icon': Icons.people.codePoint.toString()},
      {'name': '银行卡', 'icon': Icons.credit_card.codePoint.toString()},
      {'name': '邮箱', 'icon': Icons.email.codePoint.toString()},
      {'name': '游戏账号', 'icon': Icons.games.codePoint.toString()},
      {'name': '网站账号', 'icon': Icons.web.codePoint.toString()},
      {'name': '其他', 'icon': Icons.more_horiz.codePoint.toString()},
    ];

    for (var category in defaultCategories) {
      await db.insert('categories', {
        ...category,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // 修改加密方法
  static Future<String> _encrypt(String text) async {
    return EncryptionService.encrypt(text);
  }

  // 添加分类
  static Future<int> addCategory(String name, IconData icon) async {
    final db = await database;
    return await db.insert('categories', {
      'name': name,
      'icon': icon.codePoint.toString(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // 获取所有分类
  static Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await database;
    return await db.query('categories', orderBy: 'created_at DESC');
  }

  // 获取所有分类（包含密码数量）
  static Future<List<Map<String, dynamic>>> getCategoriesWithCount() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        c.*,
        COUNT(p.id) as password_count
      FROM categories c
      LEFT JOIN passwords p ON c.id = p.category_id
      GROUP BY c.id
      ORDER BY c.created_at DESC
    ''');
  }

  // 获取按分类分组的密码
  static Future<List<Map<String, dynamic>>> getPasswordsByCategory(int categoryId) async {
    final db = await database;
    
    return await db.query(
      'passwords',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'name ASC',
    );
  }

  // 添加密码
  static Future<int> addPassword(Map<String, dynamic> password) async {
    final db = await database;
    final encryptedPlain = await _encrypt(password['plainPassword']);
    
    return await db.insert('passwords', {
      'name': password['name'],
      'category_id': password['categoryId'],
      'plain_password': encryptedPlain,
      'encrypted_password': password['encryptedPassword'],
      'created_at': DateTime.now().toIso8601String(),
      'last_used': DateTime.now().toIso8601String(),
    });
  }

  // 获取所有密码
  static Future<List<Map<String, dynamic>>> getPasswords({
    bool updateOrder = true,
    bool orderByCopyCount = false,
  }) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        p.*,
        c.name as category_name,
        c.icon as category_icon,
        p.plain_password as plain_password,
        p.encrypted_password as encrypted_password
      FROM passwords p
      LEFT JOIN categories c ON p.category_id = c.id
      ${updateOrder ? 'ORDER BY ${orderByCopyCount ? "p.copy_count DESC" : "p.last_used DESC"}' : ''}
    ''');
  }

  // 记录密码复制
  static Future<void> logPasswordCopy(int passwordId, String copyType) async {
    final db = await database;
    await db.insert('copy_logs', {
      'password_id': passwordId,
      'copy_type': copyType,
      'copied_at': DateTime.now().toIso8601String(),
    });

    await db.rawUpdate('''
      UPDATE passwords 
      SET copy_count = copy_count + 1,
          last_used = ?
      WHERE id = ?
    ''', [DateTime.now().toIso8601String(), passwordId]);
  }

  static Future<void> deleteCategory(int categoryId) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [categoryId]);
  }

  // 添加删除密码的方法
  static Future<void> deletePassword(int passwordId) async {
    final db = await database;
    await db.delete('passwords', where: 'id = ?', whereArgs: [passwordId]);
  }
} 
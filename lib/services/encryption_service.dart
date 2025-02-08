import 'dart:convert';
import 'package:crypto/crypto.dart';

/// 加密服务
/// 默认实现：MD5加密，支持多种输出格式
class EncryptionService {
  /// 这是唯一的加密实现方法
  static String encrypt(String text) {

    
    // 1. 计算完整的MD5（32位小写）
    final bytes = utf8.encode(text);
    final fullMd5Lower = md5.convert(bytes).toString();
    
    // 2. 取前8位小写
    final md5_8_lower = fullMd5Lower.substring(0, 8);
    
    // 3. 将第一个字母转为大写
    String md5_8_upper_first = md5_8_lower;
    for (int i = 0; i < md5_8_lower.length; i++) {
      if (RegExp(r'[a-z]').hasMatch(md5_8_lower[i])) {
        md5_8_upper_first = md5_8_lower.substring(0, i) + 
                           md5_8_lower[i].toUpperCase() + 
                           md5_8_lower.substring(i + 1);
        break;
      }
    }
    print('首字母大写: $md5_8_upper_first');
    
    // 4. 前7位 + @符号
    final result = md5_8_upper_first.substring(0, 7) + '@';
    print('最终结果: $result');
    
    return result;
  }
} 

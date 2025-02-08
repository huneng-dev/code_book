import 'dart:convert';
import 'package:crypto/crypto.dart';

/// 加密服务
/// 示例加密逻辑，请自行增强加密服务的健壮性
class EncryptionService {
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
    // 4. 前7位 + @符号
    final result = md5_8_upper_first.substring(0, 7) + '@';

    return result;
  }
} 

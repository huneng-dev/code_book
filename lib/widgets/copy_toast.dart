import 'package:flutter/material.dart';
import 'dart:async';

class CopyToast extends StatelessWidget {
  final String message;
  final VoidCallback? onActionPressed;
  final String? actionLabel;

  const CopyToast({
    super.key,
    required this.message,
    this.onActionPressed,
    this.actionLabel,
  });

  static OverlayEntry? _currentToast;
  static Timer? _hideTimer;

  static void _hideToast() {
    _hideTimer?.cancel();
    _currentToast?.remove();
    _currentToast = null;
  }

  static void show(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    _currentToast?.remove();
    _currentToast = null;
    _hideTimer?.cancel();
    
    final toast = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // 添加一个透明的全屏点击区域
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _hideToast,
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
              // Toast 内容
              Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.8 + (0.2 * value),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: GestureDetector(
                      onTap: () {}, // 防止点击 Toast 本身时触发背景点击
                      child: CopyToast(
                        message: message,
                        actionLabel: actionLabel,
                        onActionPressed: onActionPressed != null ? () {
                          _hideToast();
                          onActionPressed();
                        } : null,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    _currentToast = toast;
    Overlay.of(context).insert(toast);

    _hideTimer = Timer(const Duration(seconds: 2), _hideToast);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      width: 320,  // 固定宽度
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            spreadRadius: -5,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,  // 让列自适应内容高度
        children: [
          Container(
            height: 64,  // 减小图标容器高度
            width: 64,   // 减小图标容器宽度
            alignment: Alignment.center,
            child: Icon(
              Icons.check_circle_rounded,
              color: colorScheme.primary,
              size: 48,  // 稍微减小图标大小
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 40,  // 减小文本容器高度
            alignment: Alignment.center,
            child: Text(
              message,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: 180,  // 减小按钮宽度
              height: 44,  // 减小按钮高度
              child: FilledButton(
                onPressed: onActionPressed,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
} 
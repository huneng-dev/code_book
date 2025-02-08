package com.example.code_book

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import android.view.WindowManager.LayoutParams
import android.view.Window
import android.os.Build

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.attributes.preferredDisplayModeId = 1
            window.attributes.preferredRefreshRate = 120f  // 设置首选刷新率为120Hz
        }
    }
}

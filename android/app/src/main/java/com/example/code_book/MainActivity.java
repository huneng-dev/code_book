import io.flutter.embedding.android.FlutterActivity;
import android.os.Bundle;
import android.view.WindowManager;

public class MainActivity extends FlutterActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // 启用高刷新率
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        getWindow().getAttributes().preferredDisplayModeId = 1;
    }
} 
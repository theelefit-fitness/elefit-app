import 'package:flutter/widgets.dart';
import 'firebase_in_app_messaging_service.dart';

class AppLifecycleService extends WidgetsBindingObserver {
  static final AppLifecycleService _instance = AppLifecycleService._internal();
  factory AppLifecycleService() => _instance;
  AppLifecycleService._internal();

  static void initialize() {
    WidgetsBinding.instance.addObserver(_instance);
    print('✅ App Lifecycle Service initialized');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        print('📱 App resumed (foreground)');
        // Trigger events when app comes to foreground
        FirebaseInAppMessagingService.triggerAppForeground();
        break;
      case AppLifecycleState.paused:
        print('⏸️ App paused (background)');
        break;
      case AppLifecycleState.inactive:
        print('😴 App inactive');
        break;
      case AppLifecycleState.detached:
        print('🔌 App detached');
        break;
      case AppLifecycleState.hidden:
        print('👻 App hidden');
        break;
    }
  }

  static void dispose() {
    WidgetsBinding.instance.removeObserver(_instance);
  }
}

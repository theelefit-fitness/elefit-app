import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'navigation_service.dart';

class OneSignalService {
  // Your OneSignal App ID
  static const String appId = "729c9710-46cf-4b96-8b51-427f3bf8dbda";
  
  static Future<void> initialize() async {
    try {
      print('🚀 Initializing OneSignal...');
      
      // Initialize OneSignal with your App ID
      OneSignal.initialize(appId);
      
      // Request notification permission
      await OneSignal.Notifications.requestPermission(true);
      
      // Set up basic notification listeners
      _setupNotificationListeners();
      
      // Set up in-app message listeners
      _setupInAppMessageListeners();
      
      // Get and display player ID
      await _getPlayerId();
      
      // Set basic user tags
      _setUserTags();
      
      // Trigger app opened event for in-app messages
      _triggerAppOpened();
      
      print('✅ OneSignal initialized successfully');
      
    } catch (e) {
      print('❌ Error initializing OneSignal: $e');
    }
  }
  
  static void _setupNotificationListeners() {
    try {
      // Handle notifications when app is in foreground
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        print('📱 Notification received: ${event.notification.title}');
      });
      
      // Handle notification clicks
      OneSignal.Notifications.addClickListener((event) {
        print('👆 Notification clicked: ${event.notification.title}');
      });
      
      // Handle permission changes
      OneSignal.Notifications.addPermissionObserver((state) {
        print('🔔 Permission: $state');
      });
      
      print('📱 Notification listeners set up');
    } catch (e) {
      print('❌ Error setting up listeners: $e');
    }
  }
  
  static void _setupInAppMessageListeners() {
    try {
      // Handle in-app message display
      OneSignal.InAppMessages.addWillDisplayListener((event) {
        print('📱 In-app message will display: ${event.message.messageId}');
      });
      
      OneSignal.InAppMessages.addDidDisplayListener((event) {
        print('📱 In-app message displayed: ${event.message.messageId}');
      });
      
      OneSignal.InAppMessages.addWillDismissListener((event) {
        print('📱 In-app message will dismiss: ${event.message.messageId}');
      });
      
      OneSignal.InAppMessages.addDidDismissListener((event) {
        print('📱 In-app message dismissed: ${event.message.messageId}');
      });
      
      OneSignal.InAppMessages.addClickListener((event) {
        print('🚨🚨🚨 IN-APP MESSAGE CLICKED! 🚨🚨🚨');
        print('👆 In-app message clicked: ${event.message.messageId}');
        print('🔍 Full click event: $event');
        print('🔍 Event type: ${event.runtimeType}');
        print('🔍 Result: ${event.result}');
        print('🔍 Result type: ${event.result.runtimeType}');
        
        // Try to prevent default URL behavior
        try {
          // Check if result has a URL that we should handle
          var url = event.result.url;
          if (url != null && url.toString().contains('product/')) {
            print('🚫 INTERCEPTING URL BEFORE BROWSER: $url');
            // Handle immediately to prevent browser opening
            String? productId = _extractProductIdFromUrl(url.toString());
            if (productId != null) {
              print('🚀 IMMEDIATE NAVIGATION TO PRODUCT: $productId');
              NavigationService.navigateToProductById(productId);
              return; // Exit early to prevent further processing
            }
          }
        } catch (e) {
          print('⚠️ Could not intercept URL: $e');
        }
        
        print('🚨 CALLING CLICK HANDLER NOW...');
        _handleInAppMessageClick(event);
        print('🚨 CLICK HANDLER COMPLETED');
      });
      
      print('📱 In-app message listeners set up');
    } catch (e) {
      print('❌ Error setting up in-app listeners: $e');
    }
  }
  
  static Future<void> _getPlayerId() async {
    try {
      await Future.delayed(Duration(seconds: 2)); // Wait for initialization
      String? playerId = OneSignal.User.pushSubscription.id;
      if (playerId != null) {
        print('🆔 Player ID: $playerId');
      } else {
        print('⚠️ Player ID not ready yet');
      }
    } catch (e) {
      print('❌ Error getting Player ID: $e');
    }
  }
  
  static void _setUserTags() {
    try {
      Map<String, String> tags = {
        'app': 'EleFit',
        'platform': 'flutter',
      };
      
      OneSignal.User.addTags(tags);
      print('🏷️ Tags set: $tags');
    } catch (e) {
      print('❌ Error setting tags: $e');
    }
  }
  
  static void _triggerAppOpened() {
    try {
      // Trigger events that can be used for in-app message targeting
      OneSignal.InAppMessages.addTrigger('app_opened', 'true');
      OneSignal.InAppMessages.addTrigger('session_start', 'true');
      print('⚡ App opened triggers set');
    } catch (e) {
      print('❌ Error setting triggers: $e');
    }
  }
  
  // Public method to manually trigger in-app messages
  static void triggerInAppMessage() {
    try {
      print('🔥 Starting manual trigger...');
      
      // Clear existing triggers first
      OneSignal.InAppMessages.clearTriggers();
      print('🧹 Cleared existing triggers');
      
      // Add new triggers
      OneSignal.InAppMessages.addTrigger('manual_trigger', 'true');
      OneSignal.InAppMessages.addTrigger('app_opened', 'true');
      OneSignal.InAppMessages.addTrigger('force_show', 'true');
      OneSignal.InAppMessages.addTrigger('test_trigger', 'true');
      
      print('🚀 Manual in-app message trigger activated');
      print('✅ Triggers set: manual_trigger=true, app_opened=true, force_show=true, test_trigger=true');
      
      // Check if in-app messages are paused
      OneSignal.InAppMessages.paused(false);
      print('▶️ Ensured in-app messages are not paused');
      
    } catch (e) {
      print('❌ Error triggering in-app message: $e');
    }
  }
  
  // Handle in-app message clicks with navigation
  static void _handleInAppMessageClick(dynamic event) {
    try {
      print('🎯 Processing in-app message click...');
      
      // Get the message data
      var message = event.message;
      var result = event.result;
      
      print('📱 Message ID: ${message.messageId}');
      print('🔍 Click result: $result');
      
      // Try to extract action from result (OneSignal v5+ structure)
      String? actionName;
      String? actionUrl;
      
      try {
        // Check if result has actionId (action name from OneSignal)
        if (result != null) {
          print('📋 Raw result: $result');
          print('📋 Result toString: ${result.toString()}');
          
          // Try different ways to access the action data in OneSignal v5+
          try {
            // Method 1: Try to access actionId property
            var actionId = result.actionId;
            if (actionId != null) {
              actionName = actionId.toString();
              print('🎯 Found actionId: $actionName');
            }
          } catch (e) {
            print('⚠️ No actionId property: $e');
          }
          
          try {
            // Method 2: Try to access clickName property
            var clickName = result.clickName;
            if (clickName != null) {
              actionName = clickName.toString();
              print('🎯 Found clickName: $actionName');
            }
          } catch (e) {
            print('⚠️ No clickName property: $e');
          }
          
          try {
            // Method 3: Try to access url property
            var url = result.url;
            if (url != null) {
              actionUrl = url.toString();
              print('🔗 Found URL: $actionUrl');
              
              // If URL contains product ID, extract it and navigate
              if (actionUrl.isNotEmpty && actionUrl.contains('product/')) {
                String? productId = _extractProductIdFromUrl(actionUrl);
                if (productId != null) {
                  print('🆔 Extracted product ID from URL: $productId');
                  print('🚫 Preventing browser navigation - handling in app');
                  NavigationService.navigateToProductById(productId);
                  return;
                }
              }
            }
          } catch (e) {
            print('⚠️ No url property: $e');
          }
          
          // Method 4: Parse from string representation (fallback ONLY)
          String resultStr = result.toString();
          if ((actionName == null || actionName.isEmpty) && resultStr.isNotEmpty && resultStr != 'null') {
            actionName = resultStr;
            print('📝 Using result string as fallback: $actionName');
          } else {
            print('ℹ️ Keeping existing actionName: $actionName');
          }
        }
      } catch (e) {
        print('❌ Could not extract action from result: $e');
      }
      
      // Skip additional data check for OneSignal v5+ compatibility
      // The actionId from result contains all needed information
      
      // Check if we have a URL first (higher priority to prevent browser opening)
      if (actionUrl != null && actionUrl.isNotEmpty && actionUrl.contains('product/')) {
        String? productId = _extractProductIdFromUrl(actionUrl);
        if (productId != null) {
          print('🚨🚨🚨 URL PRODUCT ID DETECTED: $productId 🚨🚨🚨');
          print('🚫 Intercepting URL - preventing browser navigation');
          NavigationService.navigateToProductById(productId);
          return;
        }
      }
      
      // Ignore bogus stringified objects as action name
      if (actionName != null && actionName.startsWith("Instance of")) {
        print('⚠️ Ignoring invalid actionName (stringified object): $actionName');
        actionName = null;
      }

      // Parse action name for product ID patterns
      if (actionName != null) {
        print('🎯 Action name: $actionName');
        print('🔍 Action name type: ${actionName.runtimeType}');
        print('🔍 Action name length: ${actionName.length}');
        print('🔍 Action name trimmed: "${actionName.trim()}"');
        
        // Check for JSON-like pattern in action name
        if (actionName.contains('productId')) {
          // Extract product ID from patterns like: {"productId": "8676117315803"}
          RegExp productIdRegex = RegExp(r'"productId":\s*"([^"]+)"');
          Match? match = productIdRegex.firstMatch(actionName);
          
          if (match != null) {
            String productId = match.group(1)!;
            print('🆔 Extracted product ID from JSON: $productId');
            NavigationService.navigateToProductById(productId);
            return;
          }
        }
        
        // Check for product_ prefix format (product_8101770789083)
        if (actionName.startsWith('product_')) {
          String productId = actionName.substring(8); // Remove 'product_' prefix
          if (RegExp(r'^\d+$').hasMatch(productId)) {
            print('🚨🚨🚨 PRODUCT_ FORMAT DETECTED: $actionName 🚨🚨🚨');
            print('🆔 Extracted product ID: $productId');
            print('🚀 CALLING NavigationService.navigateToProductById...');
            NavigationService.navigateToProductById(productId);
            print('✅ Navigation call completed');
            return;
          }
        }
        
        // Check for direct product ID (just numbers)
        if (RegExp(r'^\d+$').hasMatch(actionName.trim())) {
          print('🚨🚨🚨 DIRECT PRODUCT ID DETECTED: $actionName 🚨🚨🚨');
          print('🚀 CALLING NavigationService.navigateToProductById...');
          NavigationService.navigateToProductById(actionName.trim());
          print('✅ Navigation call completed');
          return;
        }
        
        // Check for URL pattern in action name
        if (actionName.contains('product/')) {
          String? productId = _extractProductIdFromUrl(actionName);
          if (productId != null) {
            print('🆔 Extracted product ID from action name URL: $productId');
            NavigationService.navigateToProductById(productId);
            return;
          }
        }
        
        // Handle standard action names
        NavigationService.handleInAppMessageAction(actionName, null);
        return;
      }
      
      // Skip additional data check since it causes errors in OneSignal v5+
      // The actionId from result is sufficient for our needs
      
      // Default fallback
      print('🛍️ No specific action found, navigating to shop');
      NavigationService.navigateToShop();
      
    } catch (e) {
      print('❌ Error handling in-app message click: $e');
      // Fallback to shop screen
      NavigationService.navigateToShop();
    }
  }
  
  // Debug function to check OneSignal status
  static void debugOneSignalStatus() {
    try {
      print('🔍 OneSignal Debug Status:');
      print('📱 App ID: $appId');
      
      String? playerId = OneSignal.User.pushSubscription.id;
      print('🆔 Player ID: ${playerId ?? "Not available"}');
      
      print('🎯 Attempting to get user state...');
      
    } catch (e) {
      print('❌ Error checking OneSignal status: $e');
    }
  }
  
  // Test method to simulate in-app message click with product ID
  static void testProductNavigation(String productId) {
    try {
      print('🧪 Testing product navigation for ID: $productId');
      NavigationService.navigateToProductById(productId);
    } catch (e) {
      print('❌ Error in test navigation: $e');
    }
  }
  
  // Extract product ID from URL
  static String? _extractProductIdFromUrl(String url) {
    try {
      print('🔍 Parsing URL: $url');
      
      // Pattern for URLs like: https://theelefit.com/product/8101770789083
      RegExp urlRegex = RegExp(r'/product/(\d+)');
      Match? match = urlRegex.firstMatch(url);
      
      if (match != null) {
        String productId = match.group(1)!;
        print('✅ Extracted product ID from URL: $productId');
        return productId;
      }
      
      // Alternative pattern for URLs with query parameters
      RegExp queryRegex = RegExp(r'[?&]id=(\d+)');
      match = queryRegex.firstMatch(url);
      
      if (match != null) {
        String productId = match.group(1)!;
        print('✅ Extracted product ID from query: $productId');
        return productId;
      }
      
      print('❌ No product ID found in URL');
      return null;
      
    } catch (e) {
      print('❌ Error parsing URL: $e');
      return null;
    }
  }
}

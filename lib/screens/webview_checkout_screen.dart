import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/cart_model.dart';
import '../models/address_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';

class WebViewCheckoutScreen extends StatefulWidget {
  final String checkoutUrl;

  const WebViewCheckoutScreen({
    Key? key,
    required this.checkoutUrl,
  }) : super(key: key);

  @override
  State<WebViewCheckoutScreen> createState() => _WebViewCheckoutScreenState();
}

class _WebViewCheckoutScreenState extends State<WebViewCheckoutScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _retryCount = 0;
  static const int maxRetries = 3;
  Timer? _timeoutTimer;
  bool _isNetworkAvailable = true;
  String _deviceInfo = '';
  String _selectedUserAgent = '';

  @override
  void initState() {
    super.initState();
    _initializeDeviceInfo();
    _checkNetworkConnectivity();
    if (kIsWeb) {
      _openInNewTab();
    } else {
      _initializeWebView();
    }
  }

  Future<void> _initializeDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceInfo = 'Android ${androidInfo.version.release} - ${androidInfo.model}';
        _selectedUserAgent = _getOptimalUserAgent(androidInfo);
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceInfo = 'iOS ${iosInfo.systemVersion} - ${iosInfo.model}';
        _selectedUserAgent = _getIOSUserAgent(iosInfo);
      }
      print('Device Info: $_deviceInfo');
      print('Selected User Agent: $_selectedUserAgent');
    } catch (e) {
      print('Error getting device info: $e');
      _selectedUserAgent = _getDefaultUserAgent();
    }
  }

  String _getOptimalUserAgent(AndroidDeviceInfo androidInfo) {
    // Use different user agents based on Android version and device capabilities
    final sdkInt = androidInfo.version.sdkInt;
    final model = androidInfo.model.toLowerCase();
    
    if (sdkInt >= 33) { // Android 13+
      return 'Mozilla/5.0 (Linux; Android ${androidInfo.version.release}; ${androidInfo.model}) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';
    } else if (sdkInt >= 29) { // Android 10+
      return 'Mozilla/5.0 (Linux; Android ${androidInfo.version.release}; ${androidInfo.model}) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Mobile Safari/537.36';
    } else if (sdkInt >= 26) { // Android 8+
      return 'Mozilla/5.0 (Linux; Android ${androidInfo.version.release}; ${androidInfo.model}) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Mobile Safari/537.36';
    } else {
      // Older Android versions
      return 'Mozilla/5.0 (Linux; Android ${androidInfo.version.release}; ${androidInfo.model}) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Mobile Safari/537.36';
    }
  }

  String _getIOSUserAgent(IosDeviceInfo iosInfo) {
    final version = iosInfo.systemVersion.replaceAll('.', '_');
    return 'Mozilla/5.0 (iPhone; CPU iPhone OS $version like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1';
  }

  String _getDefaultUserAgent() {
    if (Platform.isAndroid) {
      return 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';
    } else if (Platform.isIOS) {
      return 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1';
    }
    return 'Mozilla/5.0 (Mobile; rv:120.0) Gecko/120.0 Firefox/120.0';
  }

  Future<void> _checkNetworkConnectivity() async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      setState(() {
        _isNetworkAvailable = connectivityResult != ConnectivityResult.none;
      });
      if (!_isNetworkAvailable) {
        setState(() {
          _hasError = true;
          _errorMessage = 'No internet connection. Please check your network or try a VPN.';
        });
      } else {
        // Verify URL accessibility
        await _checkUrlAccessibility();
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Network check failed: ${e.toString()}. Try using a VPN.';
      });
    }
  }

  Future<void> _checkUrlAccessibility() async {
    try {
      final response = await http.head(Uri.parse(widget.checkoutUrl)).timeout(const Duration(seconds: 5));
      if (response.statusCode >= 400) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Checkout URL inaccessible (Status: ${response.statusCode}). Try using a VPN or different network.';
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to verify checkout URL: ${e.toString()}. Try using a VPN.';
      });
    }
  }

  void _initializeWebView() {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
        limitsNavigationsToAppBoundDomains: false,
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller = WebViewController.fromPlatformCreationParams(params);

    // Enhanced Android WebView configuration
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(kDebugMode);
      (controller.platform as AndroidWebViewController)
        ..setMediaPlaybackRequiresUserGesture(false)
        ..setUserAgent(_selectedUserAgent.isNotEmpty ? _selectedUserAgent : _getDefaultUserAgent())
        ..setGeolocationPermissionsPromptCallbacks(
          onShowPrompt: (request) async {
            return GeolocationPermissionsResponse(
              allow: false,
              retain: false,
            );
          },
        );
    }
    
    // Enhanced iOS WebView configuration
    if (controller.platform is WebKitWebViewController) {
      (controller.platform as WebKitWebViewController)
        ..setAllowsBackForwardNavigationGestures(false)
        ..setUserAgent(_selectedUserAgent.isNotEmpty ? _selectedUserAgent : _getDefaultUserAgent());
    }

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (JavaScriptMessage message) {
          print('JavaScript message: ${message.message}');
          if (message.message.contains('shop_pay_callback')) {
            if (message.message.contains('success')) {
              context.read<CartModel>().clearCart();
              Navigator.of(context).pop(true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Order placed successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            print('WebView is loading (progress : $progress%) - Device: $_deviceInfo');
          },
          onPageStarted: (String url) {
            print('Page started loading: $url - Device: $_deviceInfo');
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
            
            // Set timeout for page load (longer for slower devices)
            _timeoutTimer?.cancel();
            final timeoutDuration = Platform.isIOS ? 
                const Duration(seconds: 45) : const Duration(seconds: 35);
            _timeoutTimer = Timer(timeoutDuration, () {
              if (_isLoading) {
                setState(() {
                  _hasError = true;
                  _errorMessage = 'Page load timeout on $_deviceInfo. Please check your internet connection, try switching networks, or use a VPN.';
                  _isLoading = false;
                });
              }
            });
          },
          onPageFinished: (String url) {
            print('Page finished loading: $url - Device: $_deviceInfo');
            _timeoutTimer?.cancel();
            setState(() {
              _isLoading = false;
            });
            
            // Enhanced JavaScript injection with better error handling and address autofill
            final addressModel = context.read<AddressModel>();
            final autofillScript = addressModel.generateAutofillScript();
            
            controller.runJavaScript('''
              try {
                console.log('Checkout page loaded on: $_deviceInfo');
                
                // Auto-fill saved address if available
                $autofillScript
                
                // Enhanced payment button detection and handling
                function handlePaymentButtons() {
                  console.log('Setting up payment button handlers');
                  
                  // Google Pay button selectors
                  var googlePaySelectors = [
                    'button[aria-label*="Google Pay"]',
                    'button[data-testid*="google-pay"]',
                    'button[class*="google-pay"]',
                    'div[data-brand="google_pay"]',
                    '.google-pay-button',
                    '[data-payment-method="google_pay"]',
                    'button:contains("Google Pay")',
                    'gpay-button'
                  ];
                  
                  // Shop Pay button selectors
                  var shopPaySelectors = [
                    'button[aria-label*="Shop Pay"]',
                    'button[data-testid*="shop-pay"]',
                    'button[class*="shop-pay"]',
                    'div[data-brand="shop_pay"]',
                    '.shop-pay-button',
                    '[data-payment-method="shop_pay"]',
                    'button:contains("Shop Pay")'
                  ];
                  
                  // PayPal button selectors
                  var paypalSelectors = [
                    'button[aria-label*="PayPal"]',
                    'button[data-testid*="paypal"]',
                    'div[data-brand="paypal"]',
                    '.paypal-button',
                    '[data-payment-method="paypal"]'
                  ];
                  
                  // Function to add click listeners to payment buttons
                  function addPaymentListeners(selectors, paymentType) {
                    selectors.forEach(function(selector) {
                      var buttons = document.querySelectorAll(selector);
                      buttons.forEach(function(button) {
                        if (!button.hasAttribute('data-flutter-handled')) {
                          button.setAttribute('data-flutter-handled', 'true');
                          
                          button.addEventListener('click', function(e) {
                            console.log(paymentType + ' button clicked');
                            
                            // Allow the original click to proceed
                            setTimeout(function() {
                              // Monitor for popup blockers or redirects
                              var checkForRedirect = setInterval(function() {
                                if (window.location.href !== url || 
                                    document.querySelector('[class*="popup"], [class*="modal"], [class*="overlay"]')) {
                                  console.log('Payment flow detected for ' + paymentType);
                                  clearInterval(checkForRedirect);
                                }
                              }, 100);
                              
                              // Clear the interval after 5 seconds
                              setTimeout(function() {
                                clearInterval(checkForRedirect);
                              }, 5000);
                            }, 100);
                          });
                          
                          console.log('Added listener to ' + paymentType + ' button');
                        }
                      });
                    });
                  }
                  
                  // Add listeners for all payment types
                  addPaymentListeners(googlePaySelectors, 'Google Pay');
                  addPaymentListeners(shopPaySelectors, 'Shop Pay');
                  addPaymentListeners(paypalSelectors, 'PayPal');
                }
                
                // Call immediately and set up observer
                handlePaymentButtons();
                
                // Set up mutation observer for dynamically loaded payment buttons
                var paymentObserver = new MutationObserver(function(mutations) {
                  var hasNewButtons = false;
                  mutations.forEach(function(mutation) {
                    if (mutation.addedNodes.length > 0) {
                      mutation.addedNodes.forEach(function(node) {
                        if (node.nodeType === 1) {
                          var hasPaymentButton = node.querySelector && (
                            node.querySelector('[class*="pay"], [data-brand], [aria-label*="Pay"]') ||
                            node.matches && node.matches('[class*="pay"], [data-brand], [aria-label*="Pay"]')
                          );
                          if (hasPaymentButton) {
                            hasNewButtons = true;
                          }
                        }
                      });
                    }
                  });
                  
                  if (hasNewButtons) {
                    setTimeout(handlePaymentButtons, 500);
                  }
                });
                
                paymentObserver.observe(document.body, {
                  childList: true,
                  subtree: true
                });
                
                // Listen for Shopify checkout events
                if (window.Shopify && window.Shopify.Checkout) {
                  window.Shopify.Checkout.OrderStatus.addCallback(function(orderStatus) {
                    console.log('Order status:', orderStatus);
                    if (orderStatus.status === 'complete') {
                      window.FlutterBridge.postMessage('shop_pay_callback:success');
                    }
                  });
                }
                
                // Enhanced completion detection
                function checkForCompletion() {
                  // Enhanced detection for various checkout completion indicators
                  var thankYouElements = document.querySelectorAll([
                    '[data-testid="thank-you"]',
                    '[data-step="thank_you"]',
                    '.thank-you',
                    '.order-confirmation',
                    '.checkout-complete',
                    '.order-complete',
                    'h1:contains("Thank you")',
                    'h2:contains("Order confirmed")',
                    '.step-thank-you',
                    '[class*="thank"]',
                    '[class*="complete"]',
                    '[class*="success"]'
                  ].join(', '));
                  
                  var completionText = document.body.innerText.toLowerCase();
                  var hasCompletionText = completionText.includes('thank you') ||
                                        completionText.includes('order confirmed') ||
                                        completionText.includes('order complete') ||
                                        completionText.includes('payment successful');
                  
                  if (thankYouElements.length > 0 || hasCompletionText) {
                    console.log('Checkout completion detected via elements/text');
                    window.FlutterBridge.postMessage('shop_pay_callback:success');
                    return true;
                  }
                  return false;
                }
                
                // Check immediately
                if (!checkForCompletion()) {
                  // Set up enhanced observer with debouncing
                  var timeoutId;
                  var completionObserver = new MutationObserver(function(mutations) {
                    clearTimeout(timeoutId);
                    timeoutId = setTimeout(function() {
                      checkForCompletion();
                    }, 500);
                  });
                  
                  completionObserver.observe(document.body, {
                    childList: true,
                    subtree: true,
                    attributes: true,
                    attributeFilter: ['class', 'data-step', 'data-testid']
                  });
                  
                  // Also monitor URL changes
                  var originalPushState = history.pushState;
                  var originalReplaceState = history.replaceState;
                  
                  history.pushState = function() {
                    originalPushState.apply(history, arguments);
                    setTimeout(checkForCompletion, 1000);
                  };
                  
                  history.replaceState = function() {
                    originalReplaceState.apply(history, arguments);
                    setTimeout(checkForCompletion, 1000);
                  };
                  
                  window.addEventListener('popstate', function() {
                    setTimeout(checkForCompletion, 1000);
                  });
                }
                
              } catch (e) {
                console.error('Error in checkout detection script:', e);
              }
            ''').catchError((error) {
              print('JavaScript injection error: $error');
            });
          },
          onWebResourceError: (WebResourceError error) {
            print('Page resource error on $_deviceInfo: ${error.description}');
            setState(() {
              _hasError = true;
              _errorMessage = _getFriendlyErrorMessage(error);
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            print('Navigation request on $_deviceInfo: ${request.url}');
            
            final url = request.url.toLowerCase();
            
            // Check for external payment app schemes that should be launched externally
            final paymentSchemes = [
              'googlepay://', 'tez://', 'paytm://', 'phonepe://', 
              'upi://', 'bhim://', 'amazonpay://', 'paypal://',
              'venmo://', 'cashapp://', 'zelle://', 'applepay://',
              'samsungpay://', 'intent://', 'market://', 'play.google.com'
            ];
            
            // Check for payment app URLs that should be launched externally
            final paymentAppUrls = [
              'pay.google.com', 'payments.google.com',
              'wallet.google.com', 'pay.app.goo.gl',
              'paypal.me', 'paypal.com/checkoutnow',
              'venmo.com/pay', 'cash.app/pay'
            ];
            
            // Launch external payment apps
            if (paymentSchemes.any((scheme) => url.startsWith(scheme)) ||
                paymentAppUrls.any((appUrl) => url.contains(appUrl))) {
              print('Launching external payment app: ${request.url}');
              _launchExternalUrl(request.url);
              return NavigationDecision.prevent;
            }
            
            // Enhanced domain allowlist for web-based payments and checkout
            final allowedDomains = [
              'shopify.com', 'shopifycs.com', 'shopifysvc.com', 'myshopify.com',
              'shop.app', 'shopify-pay.com', 'shopifycdn.com',
              'paypal.com', 'paypalobjects.com', 'stripe.com', 'js.stripe.com',
              'apple.com', 'google.com', 'googlepay.com', 'googleapis.com',
              'theelefit.com', 'cdn.shopify.com',
              // Add common payment processor domains
              'razorpay.com', 'payu.in', 'ccavenue.com', 'instamojo.com',
              'checkout.com', 'adyen.com', 'worldpay.com', 'square.com',
              // Add UPI and Indian payment gateways
              'npci.org.in', 'upi.org.in', 'bharatpe.com', 'freecharge.in'
            ];
            
            final isAllowed = allowedDomains.any((domain) => 
                url.contains(domain));
            
            if (isAllowed) {
              return NavigationDecision.navigate;
            }
            
            // For security, block other external URLs but log them
            print('Blocked navigation to: ${request.url}');
            return NavigationDecision.prevent;
          },
        ),
      )..loadRequest(Uri.parse(widget.checkoutUrl));

    _controller = controller;
  }

  String _getFriendlyErrorMessage(WebResourceError error) {
    final deviceContext = _deviceInfo.isNotEmpty ? ' on $_deviceInfo' : '';
    
    switch (error.errorType) {
      case WebResourceErrorType.hostLookup:
        return 'Unable to connect to checkout server$deviceContext. This may be due to network restrictions or DNS issues. Try:\n• Switching to mobile data\n• Using a VPN\n• Changing DNS to 8.8.8.8';
      case WebResourceErrorType.timeout:
        return 'Connection timed out$deviceContext. The checkout server may be slow or unreachable. Try:\n• Waiting and retrying\n• Using a different network\n• Enabling VPN';
      case WebResourceErrorType.connect:
        return 'Failed to connect to checkout server$deviceContext. This could be due to:\n• Network firewall blocking the connection\n• ISP restrictions\n• Server maintenance\n\nSolutions:\n• Switch to mobile data\n• Use a VPN\n• Try again later';
      case WebResourceErrorType.authentication:
        return 'Authentication failed$deviceContext. The checkout session may have expired. Please:\n• Go back and try again\n• Clear app cache\n• Contact support if issue persists';
      case WebResourceErrorType.unsupportedScheme:
        return 'Unsupported URL scheme$deviceContext. The checkout link may be invalid. Please contact support.';
      case WebResourceErrorType.redirectLoop:
        return 'Redirect loop detected$deviceContext. This may be a server configuration issue. Try:\n• Clearing app cache\n• Using external browser\n• Contact support';
      case WebResourceErrorType.fileNotFound:
        return 'Checkout page not found$deviceContext. The link may be expired or invalid. Please:\n• Go back and try again\n• Contact support if issue persists';
      case WebResourceErrorType.tooManyRequests:
        return 'Too many requests$deviceContext. Please wait a moment and try again.';
      case WebResourceErrorType.unknown:
      default:
        // Provide device-specific guidance for unknown errors
        String deviceSpecificAdvice = '';
        if (Platform.isAndroid) {
          deviceSpecificAdvice = '\n\nAndroid-specific solutions:\n• Enable "Allow third-party cookies"\n• Disable battery optimization for this app\n• Try clearing WebView cache';
        } else if (Platform.isIOS) {
          deviceSpecificAdvice = '\n\niOS-specific solutions:\n• Check Safari settings\n• Enable JavaScript\n• Try restarting the app';
        }
        
        return 'Checkout page failed to load$deviceContext.\n\nError: ${error.description}\n\nGeneral solutions:\n• Check internet connection\n• Try using VPN\n• Switch networks\n• Use external browser$deviceSpecificAdvice';
    }
  }

  void _retryLoad() {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    _controller.clearCache();
    _controller.clearLocalStorage();
    _controller.loadRequest(Uri.parse(widget.checkoutUrl));
  }

  Future<void> _launchExternalUrl(String url) async {
    print('Attempting to launch external URL: $url');
    
    try {
      // Handle different types of payment URLs
      if (url.toLowerCase().startsWith('intent://')) {
        await _handleAndroidIntent(url);
      } else if (url.toLowerCase().contains('googlepay') || 
                 url.toLowerCase().contains('tez://') ||
                 url.toLowerCase().contains('pay.google.com')) {
        await _handleGooglePay(url);
      } else if (url.toLowerCase().contains('upi://') ||
                 url.toLowerCase().contains('paytm://') ||
                 url.toLowerCase().contains('phonepe://') ||
                 url.toLowerCase().contains('bhim://')) {
        await _handleUPIPayment(url);
      } else {
        // Generic external URL handling
        await _launchGenericUrl(url);
      }
    } catch (e) {
      print('Error launching external URL: $e');
      await _showPaymentError(url, e.toString());
    }
  }
  
  Future<void> _handleAndroidIntent(String intentUrl) async {
    print('Handling Android intent: $intentUrl');
    
    try {
      // Try to parse and launch the intent URL directly
      final Uri uri = Uri.parse(intentUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('Successfully launched intent URL');
        return;
      }
      
      // If direct launch fails, try to extract the package name and launch the app
      final packageMatch = RegExp(r'package=([^;]+)').firstMatch(intentUrl);
      if (packageMatch != null) {
        final packageName = packageMatch.group(1);
        print('Extracted package name: $packageName');
        
        // Try to launch the app directly
        final appUri = Uri.parse('market://details?id=$packageName');
        if (await canLaunchUrl(appUri)) {
          await launchUrl(appUri, mode: LaunchMode.externalApplication);
          return;
        }
      }
      
      throw Exception('Could not handle intent URL');
    } catch (e) {
      print('Intent handling failed: $e');
      rethrow;
    }
  }
  
  Future<void> _handleGooglePay(String url) async {
    print('Handling Google Pay URL: $url');
    
    final List<String> googlePayUrls = [
      url, // Original URL
      'googlepay://pay', // Direct Google Pay app
      'tez://pay', // Google Pay (Tez) app
      'https://pay.google.com', // Web fallback
    ];
    
    for (String payUrl in googlePayUrls) {
      try {
        final Uri uri = Uri.parse(payUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          print('Successfully launched Google Pay with URL: $payUrl');
          return;
        }
      } catch (e) {
        print('Failed to launch Google Pay URL $payUrl: $e');
        continue;
      }
    }
    
    // If all Google Pay options fail, try to open Play Store
    await _openPlayStore('com.google.android.apps.nfc.payment');
  }
  
  Future<void> _handleUPIPayment(String url) async {
    print('Handling UPI payment URL: $url');
    
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('Successfully launched UPI payment');
        return;
      }
    } catch (e) {
      print('UPI payment launch failed: $e');
    }
    
    // Fallback: Show available UPI apps
    await _showUPIAppOptions();
  }
  
  Future<void> _launchGenericUrl(String url) async {
    final Uri uri = Uri.parse(url);
    
    // Try different launch modes
    final List<LaunchMode> modes = [
      LaunchMode.externalApplication,
      LaunchMode.externalNonBrowserApplication,
      LaunchMode.platformDefault,
    ];
    
    for (LaunchMode mode in modes) {
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: mode);
          print('Successfully launched URL with mode: $mode');
          return;
        }
      } catch (e) {
        print('Failed to launch with mode $mode: $e');
        continue;
      }
    }
    
    throw Exception('Could not launch URL with any mode');
  }
  
  Future<void> _openPlayStore(String packageName) async {
    try {
      final playStoreUri = Uri.parse('market://details?id=$packageName');
      if (await canLaunchUrl(playStoreUri)) {
        await launchUrl(playStoreUri, mode: LaunchMode.externalApplication);
        return;
      }
      
      // Fallback to web Play Store
      final webPlayStoreUri = Uri.parse('https://play.google.com/store/apps/details?id=$packageName');
      if (await canLaunchUrl(webPlayStoreUri)) {
        await launchUrl(webPlayStoreUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Failed to open Play Store: $e');
    }
  }
  
  Future<void> _showUPIAppOptions() async {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('UPI Payment'),
        content: const Text('Please install a UPI app like Google Pay, PhonePe, or Paytm to complete the payment.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _openPlayStore('com.google.android.apps.nfc.payment'); // Google Pay
            },
            child: const Text('Install Google Pay'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _showPaymentError(String url, String error) async {
    if (!mounted) return;
    
    print('Payment error for URL $url: $error');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Payment app could not be opened'),
            const SizedBox(height: 4),
            Text(
              'Please ensure you have the required payment app installed',
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Install Apps',
          textColor: Colors.white,
          onPressed: () => _showUPIAppOptions(),
        ),
      ),
    );
  }

  Future<void> _openInNewTab() async {
    final Uri url = Uri.parse(widget.checkoutUrl);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
        if (mounted) {
          final completed = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Order Status'),
              content: const Text('Did you complete your order?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('NO'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('YES'),
                ),
              ],
            ),
          );

          if (completed == true) {
            context.read<CartModel>().clearCart();
            Navigator.of(context).pop(true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Order placed successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            Navigator.of(context).pop(false);
          }
        }
      } else {
        throw Exception('Could not launch URL');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: Could not open checkout page - ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop(false);
      }
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Checkout'),
          automaticallyImplyLeading: false,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Leave Checkout?'),
            content: const Text('Are you sure you want to leave the checkout process? Your progress will be lost.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('STAY'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('LEAVE'),
              ),
            ],
          ),
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Checkout'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              final shouldClose = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Leave Checkout?'),
                  content: const Text('Are you sure you want to leave the checkout process? Your progress will be lost.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('STAY'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('LEAVE'),
                    ),
                  ],
                ),
              );
              if (shouldClose == true) {
                Navigator.of(context).pop(false);
              }
            },
          ),
        ),
        body: Stack(
          children: [
            if (_hasError)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load checkout page',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_retryCount < maxRetries)
                      ElevatedButton(
                        onPressed: _retryLoad,
                        child: const Text('Retry'),
                      )
                    else ...[
                      ElevatedButton(
                        onPressed: _retryLoad,
                        child: const Text('Retry with Cache Cleared'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _openInNewTab,
                        child: const Text('Open in Browser'),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Tip: Try switching to a different network, changing DNS (e.g., 8.8.8.8), or using a VPN.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              )
            else
              WebViewWidget(controller: _controller),
            if (_isLoading)
              Container(
                color: Colors.white,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: AppTheme.accentColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading checkout...',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
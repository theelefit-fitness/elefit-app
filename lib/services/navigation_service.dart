import 'package:flutter/material.dart';
import '../widgets/main_layout.dart';
import '../screens/home_screen.dart';
import '../screens/shop_screen.dart';
import '../screens/product_details_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/wishlist_screen.dart';
import '../screens/profile_screen.dart';
import '../services/shopify_service.dart';
import 'package:provider/provider.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  static BuildContext? get context => navigatorKey.currentContext;
  
  // Navigate to specific tab in main layout
  static void navigateToTab(int tabIndex) {
    if (context == null) return;
    
    Widget page;
    switch (tabIndex) {
      case 0:
        page = const HomeScreen();
        break;
      case 1:
        page = const ShopScreen();
        break;
      case 2:
        page = const WishlistScreen();
        break;
      case 3:
        page = const CartScreen();
        break;
      case 4:
        page = const ProfileScreen();
        break;
      default:
        page = const HomeScreen();
    }

    Navigator.of(context!).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => MainLayout(
          currentIndex: tabIndex,
          child: page,
        ),
      ),
      (route) => false,
    );
  }
  
  // Navigate to home screen
  static void navigateToHome() {
    navigateToTab(0);
  }
  
  // Navigate to shop screen
  static void navigateToShop() {
    navigateToTab(1);
  }
  
  // Navigate to wishlist screen
  static void navigateToWishlist() {
    navigateToTab(2);
  }
  
  // Navigate to cart screen
  static void navigateToCart() {
    navigateToTab(3);
  }
  
  // Navigate to profile screen
  static void navigateToProfile() {
    navigateToTab(4);
  }
  
  // Navigate to product details with product data
  static void navigateToProductDetails(Map<String, dynamic> product) {
    if (context == null) return;
    
    Navigator.of(context!).push(
      MaterialPageRoute(
        builder: (context) => MainLayout(
          currentIndex: 1, // Shop tab
          child: ProductDetailsScreen(product: product),
        ),
      ),
    );
  }
  
  // Navigate to specific product by ID (fetch product data and navigate)
  static Future<void> navigateToProductById(String productId) async {
    if (context == null) return;
    
    try {
      print('🔍 Fetching product with ID: $productId');
      
      // Show loading indicator
      ScaffoldMessenger.of(context!).showSnackBar(
        SnackBar(
          content: Text('Loading product $productId...'),
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Get Shopify service from context
      final shopifyService = Provider.of<ShopifyService>(context!, listen: false);
      
      // Fetch product by ID
      Map<String, dynamic>? rawProduct = await shopifyService.getProductById(productId);
      
      print('🔍 Raw product response: $rawProduct');
      
      if (rawProduct != null && rawProduct['id'] != null) {
        print('✅ Product found: ${rawProduct['title']}');
        
        // Transform the product data to match expected format
        Map<String, dynamic> product = _transformProductData(rawProduct);
        
        // Navigate to product details
        Navigator.of(context!).push(
          MaterialPageRoute(
            builder: (context) => MainLayout(
              currentIndex: 1, // Shop tab
              child: ProductDetailsScreen(product: product),
            ),
          ),
        );
        
        // Show success message
        ScaffoldMessenger.of(context!).showSnackBar(
          SnackBar(
            content: Text('Opened: ${product['title']}'),
            duration: const Duration(seconds: 2),
          ),
        );
        
      } else {
        print('❌ Product not found with ID: $productId');
        
        // Product not found, navigate to shop
        navigateToShop();
        
        ScaffoldMessenger.of(context!).showSnackBar(
          SnackBar(
            content: Text('Product $productId not found. Showing all products.'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
    } catch (e) {
      print('❌ Error fetching product $productId: $e');
      
      // Error occurred, navigate to shop as fallback
      navigateToShop();
      
      ScaffoldMessenger.of(context!).showSnackBar(
        SnackBar(
          content: Text('Error loading product. Showing all products.'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  
  // Navigate to external URL
  static void navigateToUrl(String url) {
    if (context == null) return;
    
    // You can implement URL launcher here
    ScaffoldMessenger.of(context!).showSnackBar(
      SnackBar(
        content: Text('Opening: $url'),
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  // Handle OneSignal in-app message actions
  static void handleInAppMessageAction(String action, [Map<String, dynamic>? data]) {
    print('🧭 Handling in-app message action: $action');
    print('📊 Action data: $data');
    
    switch (action.toLowerCase()) {
      case 'shop':
      case 'browse':
      case 'explore':
        navigateToShop();
        break;
        
      case 'home':
      case 'dashboard':
        navigateToHome();
        break;
        
      case 'cart':
      case 'checkout':
        navigateToCart();
        break;
        
      case 'wishlist':
      case 'favorites':
        navigateToWishlist();
        break;
        
      case 'profile':
      case 'account':
        navigateToProfile();
        break;
        
      case 'product':
        if (data != null && data.containsKey('productId')) {
          navigateToProductById(data['productId']);
        } else if (data != null && data.containsKey('product')) {
          navigateToProductDetails(data['product']);
        } else {
          navigateToShop();
        }
        break;
        
      default:
        print('⚠️ Unknown action: $action, navigating to home');
        navigateToHome();
    }
  }
  
  // Handle OneSignal in-app message URL clicks
  static void handleInAppMessageUrl(String url) {
    print('🔗 Handling in-app message URL: $url');
    
    // Parse URL and navigate accordingly
    Uri uri = Uri.parse(url);
    
    if (uri.host == 'theelefit.com' || uri.host == 'localhost') {
      // Internal app URLs
      String path = uri.path;
      Map<String, String> params = uri.queryParameters;
      
      if (path.startsWith('/shop')) {
        navigateToShop();
      } else if (path.startsWith('/product/')) {
        String productId = path.split('/').last;
        navigateToProductById(productId);
      } else if (path.startsWith('/cart')) {
        navigateToCart();
      } else if (path.startsWith('/profile')) {
        navigateToProfile();
      } else {
        navigateToHome();
      }
    } else {
      // External URLs - you can implement URL launcher
      navigateToUrl(url);
    }
  }
  
  // Transform Shopify API product data to match app's expected format
  static Map<String, dynamic> _transformProductData(Map<String, dynamic> rawProduct) {
    try {
      // Extract images from Shopify format
      List<String> images = [];
      if (rawProduct['images'] != null && rawProduct['images']['edges'] != null) {
        images = (rawProduct['images']['edges'] as List)
            .map((edge) => (edge['node']['url'] as String?) ?? '')
            .where((url) => url.isNotEmpty)
            .toList();
      }
      
      // If no images, add a placeholder
      if (images.isEmpty) {
        images = ['https://via.placeholder.com/400x400?text=No+Image'];
      }
      
      // Extract price from Shopify priceRange
      double price = 0.0;
      if (rawProduct['priceRange'] != null && 
          rawProduct['priceRange']['minVariantPrice'] != null) {
        String priceStr = rawProduct['priceRange']['minVariantPrice']['amount']?.toString() ?? '0.0';
        price = double.tryParse(priceStr) ?? 0.0;
      }
      
      // Transform the product data to match ProductDetailsScreen expected format
      Map<String, dynamic> transformedProduct = {
        // Basic product info
        'id': rawProduct['id']?.toString() ?? 'unknown',
        'name': rawProduct['title']?.toString() ?? 'Unknown Product', // Map title to name
        'title': rawProduct['title']?.toString() ?? 'Unknown Product', // Keep both for compatibility
        'handle': rawProduct['handle']?.toString() ?? '',
        'description': rawProduct['description']?.toString() ?? '',
        
        // Images
        'images': images,
        'image': images.isNotEmpty ? images.first : 'https://via.placeholder.com/400x400?text=No+Image',
        
        // Price
        'price': price,
        'priceRange': rawProduct['priceRange'] ?? {
          'minVariantPrice': {
            'amount': price.toString(),
            'currencyCode': 'USD'
          }
        },
        
        // Variants
        'variants': rawProduct['variants'] ?? {'edges': []},
      };
      
      print('🔄 Transformed product data: ${transformedProduct['name']}');
      print('💰 Price: ${transformedProduct['price']}');
      print('📸 Images count: ${images.length}');
      print('🏷️ Variants: ${rawProduct['variants']?['edges']?.length ?? 0}');
      print('📋 Final product keys: ${transformedProduct.keys.toList()}');
      
      return transformedProduct;
      
    } catch (e) {
      print('❌ Error transforming product data: $e');
      
      // Return a basic product structure as fallback
      return {
        'id': rawProduct['id']?.toString() ?? 'unknown',
        'name': rawProduct['title']?.toString() ?? 'Unknown Product',
        'title': rawProduct['title']?.toString() ?? 'Unknown Product',
        'handle': rawProduct['handle']?.toString() ?? '',
        'description': rawProduct['description']?.toString() ?? '',
        'images': ['https://via.placeholder.com/400x400?text=No+Image'],
        'image': 'https://via.placeholder.com/400x400?text=No+Image',
        'price': 0.0,
        'variants': {'edges': []},
        'priceRange': {
          'minVariantPrice': {
            'amount': '0.00',
            'currencyCode': 'USD'
          }
        },
      };
    }
  }
  
  // Test method with hardcoded product data to bypass API issues
  static void testWithHardcodedProduct() {
    if (context == null) return;
    
    try {
      print('🧪 Testing with hardcoded product data...');
      
      // Create a minimal product structure that should work
      Map<String, dynamic> testProduct = {
        'id': 'gid://shopify/Product/8101770789083',
        'name': 'EleFit Titan Duffle Bag – Test',
        'title': 'EleFit Titan Duffle Bag – Test',
        'handle': 'test-gym-bag',
        'description': 'This is a test product for debugging navigation.',
        'price': 29.99,
        'image': 'https://via.placeholder.com/400x400?text=Test+Product',
        'images': [
          'https://via.placeholder.com/400x400?text=Test+Product+1',
          'https://via.placeholder.com/400x400?text=Test+Product+2',
        ],
        'variants': {
          'edges': [
            {
              'node': {
                'id': 'gid://shopify/ProductVariant/test123',
                'title': 'Default Title',
                'price': {
                  'amount': '29.99',
                  'currencyCode': 'USD'
                },
                'availableForSale': true,
              }
            }
          ]
        },
        'priceRange': {
          'minVariantPrice': {
            'amount': '29.99',
            'currencyCode': 'USD'
          }
        },
      };
      
      print('🚀 Navigating to test product...');
      
      // Navigate directly to ProductDetailsScreen
      Navigator.of(context!).push(
        MaterialPageRoute(
          builder: (context) => MainLayout(
            currentIndex: 1, // Shop tab
            child: ProductDetailsScreen(product: testProduct),
          ),
        ),
      );
      
      ScaffoldMessenger.of(context!).showSnackBar(
        const SnackBar(
          content: Text('🧪 Opened test product with hardcoded data'),
          duration: Duration(seconds: 3),
        ),
      );
      
    } catch (e) {
      print('❌ Error with hardcoded test: $e');
      ScaffoldMessenger.of(context!).showSnackBar(
        SnackBar(
          content: Text('❌ Test failed: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Debug method to fetch and display available products
  static Future<void> debugAvailableProducts() async {
    if (context == null) return;
    
    try {
      print('🔍 Fetching available products from Shopify...');
      
      // Get Shopify service from context
      final shopifyService = Provider.of<ShopifyService>(context!, listen: false);
      
      // Fetch products
      Map<String, dynamic>? productsData = await shopifyService.getProducts(first: 10);
      
      if (productsData != null && productsData['products'] != null) {
        List products = productsData['products']['edges'];
        
        print('📦 Found ${products.length} products:');
        
        for (int i = 0; i < products.length; i++) {
          var product = products[i]['node'];
          String id = product['id']?.toString() ?? 'No ID';
          String title = product['title']?.toString() ?? 'No Title';
          
          // Extract numeric ID from Shopify GID
          String numericId = id.replaceAll('gid://shopify/Product/', '');
          
          print('${i + 1}. ID: $numericId');
          print('   Title: $title');
          print('   Full GID: $id');
          print('---');
        }
        
        // Show first product as example
        if (products.isNotEmpty) {
          var firstProduct = products[0]['node'];
          String firstId = firstProduct['id']?.toString() ?? '';
          String firstNumericId = firstId.replaceAll('gid://shopify/Product/', '');
          String firstTitle = firstProduct['title']?.toString() ?? 'Unknown';
          
          ScaffoldMessenger.of(context!).showSnackBar(
            SnackBar(
              content: Text('Found ${products.length} products. First: $firstTitle (ID: $firstNumericId)'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
        
      } else {
        print('❌ No products found or error in response');
        ScaffoldMessenger.of(context!).showSnackBar(
          const SnackBar(
            content: Text('No products found in store'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      
    } catch (e) {
      print('❌ Error fetching products: $e');
      ScaffoldMessenger.of(context!).showSnackBar(
        SnackBar(
          content: Text('Error fetching products: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

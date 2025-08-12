import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/cart_model.dart';
import 'models/wishlist_model.dart';
import 'models/address_model.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/product_details_screen.dart';
import 'theme/app_theme.dart';
import 'services/shopify_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'providers/location_provider.dart';
import 'widgets/main_layout.dart';
import 'screens/OrdersScreen.dart';
import 'screens/HelpScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppTheme.surfaceColor,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Shopify service
  final shopifyService = ShopifyService();
  await shopifyService.initialize();

  // Test API connection
  final isConnected = await shopifyService.testConnection();
  print('Shopify API Connection Test: ${isConnected ? 'Success' : 'Failed'}');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => CartModel()),
        ChangeNotifierProvider(create: (ctx) => WishlistModel()),
        ChangeNotifierProvider(create: (ctx) => AddressModel()),
        ChangeNotifierProvider(create: (ctx) => ThemeProvider()),
        ChangeNotifierProvider(create: (ctx) => LocationProvider()),
        Provider.value(value: shopifyService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'EleFit',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          debugShowCheckedModeBanner: false,
          home: MainLayout(
            currentIndex: 0,
            child: const HomeScreen(),
          ),
          onGenerateRoute: (settings) {
            if (settings.name == '/product-details') {
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (context) => MainLayout(
                  currentIndex: 1, // Shop tab
                  child: ProductDetailsScreen(product: args['product']),
                ),
              );
            }
            return null;
          },
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/shopify_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../providers/location_provider.dart';
import '../screens/OrdersScreen.dart';
import '../screens/HelpScreen.dart';
import '../screens/address_screen.dart';
import '../models/address_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isAuthenticated = false;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final email = prefs.getString('user_email');
    setState(() {
      _isAuthenticated = token != null;
      _userEmail = email;
    });
  }

  Future<void> _signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_email');
    setState(() {
      _isAuthenticated = false;
      _userEmail = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: _isAuthenticated
            ? [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await _signOut();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Signed out successfully')),
                      );
                    }
                  },
                ),
              ]
            : null,
      ),
      body: _isAuthenticated ? _buildProfileContent() : _buildSignInPrompt(),
    );
  }

  Widget _buildSignInPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_circle_outlined,
            size: 64,
            color: Theme.of(context).primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Sign in to view your profile',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Access your orders, wishlist, and more',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (context) => const AuthScreen(),
                ),
              );
              if (result == true) {
                await _checkAuthStatus();
              }
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_userEmail != null)
          ListTile(
            leading: const Icon(Icons.email),
            title: Text(_userEmail!),
          ),
        const Divider(),
        _buildThemeToggle(context),
        if (kIsWeb) ...[
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Select Region'),
            trailing: DropdownButton<String>(
              value: context.watch<LocationProvider>().countryCode,
              items: const [
                DropdownMenuItem(value: 'US', child: Text('United States (USD)')),
                DropdownMenuItem(value: 'IN', child: Text('India (INR)')),
              ],
              onChanged: (String? newValue) {
                if (newValue != null) {
                  context.read<LocationProvider>().setCountry(newValue);
                }
              },
            ),
          ),
        ],
        const Divider(),
        ListTile(
          leading: const Icon(Icons.shopping_bag_outlined),
          title: const Text('My Orders'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const OrdersScreen(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.location_on_outlined),
          title: const Text('Shipping Addresses'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AddressScreen(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.payment),
          title: const Text('Payment Methods'),
          onTap: () {
            // Navigate to payment methods screen
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.settings_outlined),
          title: const Text('Settings'),
          onTap: () {
            // Navigate to settings screen
          },
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('About'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const HelpScreen(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.help_outline),
          title: const Text('Help & Support'),
          onTap: () {
            // Navigate to help screen
          },
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Sign Out'),
          onTap: () async {
            await _signOut();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Signed out successfully')),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildThemeToggle(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.themeMode == ThemeMode.dark;
        return ListTile(
          leading: Icon(
            isDark ? Icons.dark_mode : Icons.light_mode,
            color: Theme.of(context).iconTheme.color,
          ),
          title: Text(
            'Dark Mode',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          trailing: Switch(
            value: isDark,
            onChanged: (value) {
              themeProvider.toggleTheme();
            },
            activeColor: AppTheme.accentColor,
          ),
        );
      },
    );
  }
}
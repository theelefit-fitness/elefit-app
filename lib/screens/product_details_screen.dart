import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart_model.dart';
import '../theme/app_theme.dart';
import '../models/product_model.dart';
import 'cart_screen.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import '../widgets/main_layout.dart';
import '../models/wishlist_model.dart';
import '../providers/location_provider.dart';
import '../screens/home_screen.dart';
import '../screens/shop_screen.dart';
import '../screens/wishlist_screen.dart';
import '../screens/profile_screen.dart';
import '../widgets/bottom_nav_bar.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsScreen({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _selectedSize = 0;
  int _quantity = 1;
  late String _selectedVariantId;
  int _currentImageIndex = 0;
  late List<String> _productImages;
  List<Map<String, dynamic>>? _variants;

  @override
  void initState() {
    super.initState();
    _initializeProductData();
  }

  void _initializeProductData() {
    // Initialize variants
    if (widget.product['variants'] != null && 
        widget.product['variants']['edges'] != null) {
      _variants = (widget.product['variants']['edges'] as List)
          .map((edge) => edge['node'] as Map<String, dynamic>)
          .toList();
    } else {
      _variants = [];
    }

    // Set initial variant ID
    _selectedVariantId = _variants?.isNotEmpty == true 
        ? _variants![0]['id'] 
        : '';

    // Initialize images
    _productImages = List<String>.from(widget.product['images'] ?? [widget.product['image']]);
  }

  void _updateSelectedVariant(int variantIndex) {
    if (_variants?.isNotEmpty == true && variantIndex < _variants!.length) {
      setState(() {
        _selectedSize = variantIndex;
        _selectedVariantId = _variants![variantIndex]['id'];
      });
    }
  }

  void _navigateToCart() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MainLayout(
          currentIndex: 3, // Cart tab
          child: const CartScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 0,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              Consumer<WishlistModel>(
                builder: (context, wishlist, child) {
                  final isInWishlist = wishlist.isInWishlist(widget.product['id']);
                  return IconButton(
                    icon: Icon(
                      isInWishlist ? Icons.favorite : Icons.favorite_border,
                      color: isInWishlist ? Colors.red : null,
                    ),
                    onPressed: () {
                      wishlist.toggleWishlist({
                        'id': widget.product['id'],
                        'title': widget.product['name'],
                        'price': widget.product['price'] ?? 0.0,
                        'imageUrl': widget.product['image'] ?? '',
                        'description': widget.product['description'] ?? '',
                        'variantId': _selectedVariantId,
                        'variants': _variants,
                      });
                    },
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {},
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductImage(),
                _buildProductInfo(),
                _buildSizeSelector(),
                _buildQuantitySelector(),
                _buildDescription(),
                const SizedBox(height: 100), // Space for bottom bar
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, -4),
              blurRadius: 8,
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Price',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Consumer<LocationProvider>(
                      builder: (context, locationProvider, child) {
                        return Text(
                          locationProvider.formatPrice(widget.product['price'] ?? 0.0),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final cartModel = context.read<CartModel>();
                  cartModel.addToCart(
                    {
                      'id': widget.product['id'],
                      'title': widget.product['name'] ?? '',
                      'price': widget.product['price'] ?? 0.0,
                      'imageUrl': widget.product['image'] ?? '',
                      'description': widget.product['description'] ?? '',
                    },
                    _selectedVariantId,
                    _quantity,
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Added to cart'),
                      duration: const Duration(seconds: 2),
                      action: SnackBarAction(
                        label: 'VIEW CART',
                        onPressed: _navigateToCart,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                ),
                child: const Text('Add to Cart'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    return Hero(
      tag: 'product_${widget.product['id']}',
      child: Container(
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
        ),
        child: Stack(
          children: [
            FlutterCarousel(
              options: CarouselOptions(
                height: 300,
                showIndicator: true,
                viewportFraction: 1.0,
                enableInfiniteScroll: true,
                autoPlay: false,
                slideIndicator: CircularSlideIndicator(),
                initialPage: _currentImageIndex,
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentImageIndex = index;
                  });
                },
              ),
              items: _productImages.map((imageUrl) {
                return Builder(
                  builder: (BuildContext context) {
                    return Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: Colors.grey,
                          ),
                        );
                      },
                    );
                  },
                );
              }).toList(),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.photo_library,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_currentImageIndex + 1}/${_productImages.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
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

  Widget _buildProductInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.product['name'],
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Consumer<LocationProvider>(
                builder: (context, locationProvider, child) {
                  return Text(
                    locationProvider.formatPrice(widget.product['price'] ?? 0.0),
                    style: TextStyle(
                      color: AppTheme.accentColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '20% OFF',
                  style: TextStyle(
                    color: AppTheme.accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.star,
                color: Colors.amber,
                size: 20,
              ),
              const SizedBox(width: 4),
              const Text(
                '4.8',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(256 Reviews)',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSizeSelector() {
    if (_variants == null || _variants!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Variant',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(
                _variants!.length,
                (index) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ChoiceChip(
                    label: Text(_variants![index]['title'] ?? 'Variant ${index + 1}'),
                    selected: _selectedSize == index,
                    onSelected: (selected) {
                      if (selected) {
                        _updateSelectedVariant(index);
                      }
                    },
                    backgroundColor: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.darkGrey
                        : Colors.grey.shade100,
                    selectedColor: AppTheme.accentColor.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: _selectedSize == index
                          ? AppTheme.accentColor
                          : Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.textColor
                              : AppTheme.lightTextColor,
                      fontWeight: _selectedSize == index ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: _selectedSize == index
                            ? AppTheme.accentColor
                            : Colors.transparent,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            'Quantity',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    if (_quantity > 1) {
                      setState(() {
                        _quantity--;
                      });
                    }
                  },
                ),
                Text(
                  _quantity.toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      _quantity++;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            widget.product['description'],
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getPageForIndex(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const ShopScreen();
      case 2:
        return const WishlistScreen();
      case 3:
        return const CartScreen();
      case 4:
        return const ProfileScreen();
      default:
        return const HomeScreen();
    }
  }
}
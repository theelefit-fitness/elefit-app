import 'package:graphql/client.dart';
import 'dart:async';

class ShopifyService {
  static const String _storeUrl = 'theelefit.com';
  static const String _storefrontAccessToken = '3476fc91bc4860c5b02aea3983766cb1';
  static const String _apiKey = '307e11a2d080bd92db478241bc9d20dc';
  static const String _apiSecretKey = '21eb801073c48a83cd3dc7093077d087';
  
  GraphQLClient? _client;
  bool _isInitialized = false;

  ShopifyService() {
    initialize();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    final HttpLink httpLink = HttpLink(
      'https://$_storeUrl/api/2024-01/graphql',
      defaultHeaders: {
        'X-Shopify-Storefront-Access-Token': _storefrontAccessToken,
        'Content-Type': 'application/json',
      },
    );

    _client = GraphQLClient(
      cache: GraphQLCache(),
      link: httpLink,
      defaultPolicies: DefaultPolicies(
        query: Policies(
          fetch: FetchPolicy.noCache,
        ),
        mutate: Policies(
          fetch: FetchPolicy.noCache,
        ),
      ),
    );

    _isInitialized = true;
  }

  Future<GraphQLClient> get client async {
    if (!_isInitialized) {
      await initialize();
    }
    return _client!;
  }

  Future<String?> createCheckout(List<Map<String, dynamic>> items, {
    String? customerAccessToken,
    Map<String, dynamic>? shippingAddress,
  }) async {
    try {
      final graphQLClient = await client;
      
      print('Creating cart with items: $items');
      print('Customer access token: ${customerAccessToken != null ? 'provided' : 'not provided'}');
      print('Shipping address: ${shippingAddress != null ? 'provided' : 'not provided'}');

      // Step 1: Validate customer access token if provided
      if (customerAccessToken != null) {
        print('Validating customer access token...');
        final isValidToken = await _validateCustomerAccessToken(customerAccessToken);
        if (!isValidToken) {
          print('Customer access token is invalid or expired, proceeding without authentication');
          customerAccessToken = null;
        } else {
          print('Customer access token is valid');
        }
      }

      // Step 2: Create cart with customer authentication if available
      String createCartMutation;
      Map<String, dynamic> cartVariables = {};
      
      if (customerAccessToken != null) {
        // Enhanced cart creation with customer authentication
        createCartMutation = '''
          mutation cartCreate(\$input: CartInput!) {
            cartCreate(input: \$input) {
              cart {
                id
                checkoutUrl
                buyerIdentity {
                  email
                  phone
                  customer {
                    id
                    email
                    firstName
                    lastName
                  }
                }
              }
              userErrors {
                field
                message
              }
            }
          }
        ''';
        
        cartVariables = {
          'input': {
            'buyerIdentity': {
              'customerAccessToken': customerAccessToken,
            }
          }
        };
      } else {
        // Simple cart creation without authentication
        createCartMutation = '''
          mutation cartCreate {
            cartCreate {
              cart {
                id
                checkoutUrl
              }
              userErrors {
                field
                message
              }
            }
          }
        ''';
      }

      // Create cart
      final createCartResult = await graphQLClient.mutate(
        MutationOptions(
          document: gql(createCartMutation),
          variables: cartVariables,
        ),
      );

      if (createCartResult.hasException) {
        print('Error creating cart: ${createCartResult.exception}');
        return null;
      }

      final cartData = createCartResult.data?['cartCreate'];
      if (cartData == null || cartData['cart'] == null) {
        print('Invalid cart data received');
        print('Full response: ${createCartResult.data}');
        return null;
      }

      // Debug: Log cart creation result
      final cart = cartData['cart'];
      final cartId = cart['id'] as String;
      print('Cart created successfully with ID: $cartId');
      
      // Debug: Check if buyer identity was set
      if (cart['buyerIdentity'] != null) {
        final buyerIdentity = cart['buyerIdentity'];
        print('Buyer identity set: ${buyerIdentity}');
        if (buyerIdentity['customer'] != null) {
          final customer = buyerIdentity['customer'];
          print('Customer authenticated: ${customer['email']} (${customer['firstName']} ${customer['lastName']})');
        } else {
          print('Warning: Buyer identity exists but no customer data');
        }
      } else {
        print('Warning: No buyer identity in cart - customer authentication may have failed');
      }
      
      // Add lines mutation
      const String addLinesMutation = '''
        mutation cartLinesAdd(\$cartId: ID!, \$lines: [CartLineInput!]!) {
          cartLinesAdd(cartId: \$cartId, lines: \$lines) {
            cart {
              id
              checkoutUrl
              lines(first: 10) {
                edges {
                  node {
                    id
                    quantity
                    merchandise {
                      ... on ProductVariant {
                        id
                      }
                    }
                  }
                }
              }
            }
            userErrors {
              field
              message
            }
          }
        }
      ''';

      // Format line items - ensure proper variant ID format
      final lines = items.map((item) {
        String variantId = item['variantId'].toString();
        
        // If the ID doesn't have the proper Shopify format, add it
        if (!variantId.startsWith('gid://shopify/ProductVariant/')) {
          // Remove any existing Shopify prefix if present
          variantId = variantId.replaceAll('gid://shopify/ProductVariant/', '');
          variantId = variantId.replaceAll('gid://shopify/Product/', '');
          // Add the correct prefix
          variantId = 'gid://shopify/ProductVariant/$variantId';
        }
        
        return {
          'merchandiseId': variantId,
          'quantity': item['quantity'],
        };
      }).toList();

      print('Adding lines to cart: $lines');

      // Add items to cart
      final addLinesResult = await graphQLClient.mutate(
        MutationOptions(
          document: gql(addLinesMutation),
          variables: {
            'cartId': cartId,
            'lines': lines,
          },
        ),
      );

      if (addLinesResult.hasException) {
        print('Error adding lines to cart: ${addLinesResult.exception}');
        return null;
      }

      final addLinesData = addLinesResult.data?['cartLinesAdd'];
      if (addLinesData == null) {
        print('Invalid response data received');
        print('Response data: ${addLinesResult.data}');
        return null;
      }

      if (addLinesData['userErrors'] != null && 
          (addLinesData['userErrors'] as List).isNotEmpty) {
        print('Cart line errors: ${addLinesData['userErrors']}');
        return null;
      }

      if (addLinesData['cart'] == null) {
        print('Invalid cart data received after adding lines');
        print('Response data: ${addLinesResult.data}');
        return null;
      }

      // Step 3: Update cart with shipping address if available
      String? finalCheckoutUrl = addLinesData['cart']['checkoutUrl'] as String?;
      if (finalCheckoutUrl == null) {
        print('No checkout URL returned');
        return null;
      }

      if (shippingAddress != null) {
        print('Updating cart with shipping address...');
        
        const String updateCartMutation = '''
          mutation cartBuyerIdentityUpdate(\$cartId: ID!, \$buyerIdentity: CartBuyerIdentityInput!) {
            cartBuyerIdentityUpdate(cartId: \$cartId, buyerIdentity: \$buyerIdentity) {
              cart {
                id
                checkoutUrl
                buyerIdentity {
                  email
                  phone
                  deliveryAddressPreferences {
                    ... on MailingAddress {
                      address1
                      address2
                      city
                      province
                      country
                      zip
                    }
                  }
                }
              }
              userErrors {
                field
                message
              }
            }
          }
        ''';

        Map<String, dynamic> buyerIdentity = {};
        
        // Add customer access token if available
        if (customerAccessToken != null) {
          buyerIdentity['customerAccessToken'] = customerAccessToken;
        }
        
        // Add delivery address preferences only if shippingAddress is not null
        if (shippingAddress != null) {
          buyerIdentity['deliveryAddressPreferences'] = [
            {
              'deliveryAddress': {
                'address1': shippingAddress['address1'],
                'address2': shippingAddress['address2'] ?? '',
                'city': shippingAddress['city'],
                'company': shippingAddress['company'] ?? '',
                'country': shippingAddress['country'],
                'firstName': shippingAddress['firstName'],
                'lastName': shippingAddress['lastName'],
                'phone': shippingAddress['phone'] ?? '',
                'province': shippingAddress['province'],
                'zip': shippingAddress['zip'],
              }
            }
          ];
        }

        final updateResult = await graphQLClient.mutate(
          MutationOptions(
            document: gql(updateCartMutation),
            variables: {
              'cartId': cartId,
              'buyerIdentity': buyerIdentity,
            },
          ),
        );

        if (updateResult.hasException) {
          print('Warning: Could not update cart with address: ${updateResult.exception}');
          // Continue with original checkout URL even if address update fails
        } else {
          final updateData = updateResult.data?['cartBuyerIdentityUpdate'];
          if (updateData != null && updateData['cart'] != null) {
            final updatedCheckoutUrl = updateData['cart']['checkoutUrl'] as String?;
            if (updatedCheckoutUrl != null) {
              finalCheckoutUrl = updatedCheckoutUrl;
              print('Successfully updated cart with shipping address');
            }
          }
        }
      }

      print('Created cart and got checkout URL: $finalCheckoutUrl');
      return finalCheckoutUrl;
    } catch (e, stackTrace) {
      print('Exception while creating cart: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  Future<bool> _validateCustomerAccessToken(String customerAccessToken) async {
    const String validateQuery = '''
      query customer(\$customerAccessToken: String!) {
        customer(customerAccessToken: \$customerAccessToken) {
          id
          email
          firstName
          lastName
        }
      }
    ''';

    try {
      final graphQLClient = await client;
      final result = await graphQLClient.query(
        QueryOptions(
          document: gql(validateQuery),
          variables: {
            'customerAccessToken': customerAccessToken,
          },
          fetchPolicy: FetchPolicy.noCache,
        ),
      );

      if (result.hasException) {
        print('Customer validation error: ${result.exception}');
        return false;
      }

      final customerData = result.data?['customer'];
      if (customerData != null) {
        print('Customer validated: ${customerData['email']} (${customerData['firstName']} ${customerData['lastName']})');
        return true;
      }
      
      print('Customer access token is invalid or expired');
      return false;
    } catch (e) {
      print('Customer validation failed: $e');
      return false;
    }
  }

  Future<bool> testConnection() async {
    const String testQuery = '''
      query {
        shop {
          name
          primaryDomain {
            url
          }
        }
      }
    ''';

    try {
      final graphQLClient = await client;
      final result = await graphQLClient.query(
        QueryOptions(
          document: gql(testQuery),
          fetchPolicy: FetchPolicy.noCache,
        ),
      );

      if (result.hasException) {
        print('API Test Error: ${result.exception}');
        return false;
      }

      final shopData = result.data?['shop'];
      if (shopData != null) {
        print('Connected to shop: ${shopData['name']}');
        print('Shop URL: ${shopData['primaryDomain']['url']}');
        return true;
      }
      return false;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getProducts({int first = 20, String? collectionId}) async {
    String query = '''
      query {
        products(first: $first${collectionId != null ? ', query: "collection_id:$collectionId"' : ''}) {
          edges {
            node {
              id
              title
              handle
              description
              priceRange {
                minVariantPrice {
                  amount
                  currencyCode
                }
              }
              images(first: 5) {
                edges {
                  node {
                    url
                    altText
                  }
                }
              }
              variants(first: 10) {
                edges {
                  node {
                    id
                    title
                    price {
                      amount
                      currencyCode
                    }
                    availableForSale
                    selectedOptions {
                      name
                      value
                    }
                  }
                }
              }
            }
          }
        }
      }
    ''';

    try {
      final graphQLClient = await client;
      final QueryOptions options = QueryOptions(
        document: gql(query),
        fetchPolicy: FetchPolicy.noCache,
      );

      final QueryResult result = await graphQLClient.query(options);

      if (result.hasException) {
        print('Error fetching products: ${result.exception}');
        return null;
      }

      return result.data;
    } catch (e) {
      print('Exception while fetching products: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> customerAccessTokenCreate({
    required String email,
    required String password,
  }) async {
    const String mutation = '''
      mutation customerAccessTokenCreate(\$input: CustomerAccessTokenCreateInput!) {
        customerAccessTokenCreate(input: \$input) {
          customerAccessToken {
            accessToken
            expiresAt
          }
          customerUserErrors {
            code
            field
            message
          }
        }
      }
    ''';

    try {
      final graphQLClient = await client;
      final MutationOptions options = MutationOptions(
        document: gql(mutation),
        variables: {
          'input': {
            'email': email,
            'password': password,
          },
        },
      );

      final QueryResult result = await graphQLClient.mutate(options);

      if (result.hasException) {
        print('Error creating access token: ${result.exception}');
        return null;
      }

      return result.data;
    } catch (e) {
      print('Exception while creating access token: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> createCustomer({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    const String mutation = '''
      mutation customerCreate(\$input: CustomerCreateInput!) {
        customerCreate(input: \$input) {
          customer {
            id
            email
            firstName
            lastName
          }
          customerUserErrors {
            code
            field
            message
          }
        }
      }
    ''';

    try {
      final graphQLClient = await client;
      final MutationOptions options = MutationOptions(
        document: gql(mutation),
        variables: {
          'input': {
            'email': email,
            'password': password,
            'firstName': firstName,
            'lastName': lastName,
          },
        },
      );

      final QueryResult result = await graphQLClient.mutate(options);

      if (result.hasException) {
        print('Error creating customer: ${result.exception}');
        return null;
      }

      return result.data;
    } catch (e) {
      print('Exception while creating customer: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getCustomerOrders({required String accessToken}) async {
    const String query = '''
      query customer(\$accessToken: String!) {
        customer(customerAccessToken: \$accessToken) {
          orders(first: 20) {
            edges {
              node {
                id
                orderNumber
                processedAt
                totalPrice {
                  amount
                  currencyCode
                }
                fulfillmentStatus
                lineItems(first: 10) {
                  edges {
                    node {
                      title
                      quantity
                      variant {
                        id
                        title
                        price {
                          amount
                          currencyCode
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    ''';

    try {
      final graphQLClient = await client;
      final QueryOptions options = QueryOptions(
        document: gql(query),
        variables: {
          'accessToken': accessToken,
        },
        fetchPolicy: FetchPolicy.noCache,
      );

      final QueryResult result = await graphQLClient.query(options);

      if (result.hasException) {
        print('Error fetching orders: ${result.exception}');
        return null;
      }

      return result.data;
    } catch (e) {
      print('Exception while fetching orders: $e');
      return null;
    }
  }
}
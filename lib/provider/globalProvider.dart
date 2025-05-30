import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shop_app/models/comment.dart';
import 'package:shop_app/repository/repository.dart';
import '../models/cart_model.dart';
import '../models/products.dart';

class Global_provider extends ChangeNotifier {
  final MyRepository? repository;

  Global_provider(this.repository);

  User? _user;
  User? get user => _user;

  String? _token;
  String? get token => _token;

  int? _userId;
  int? get userId => _userId;

  List<ProductModel> products = [];

  final List<ProductModel> _favoriteItems = [];
  List<ProductModel> get favoriteItems => List.unmodifiable(_favoriteItems);

  List<CartItem> _cartItems = [];
  List<CartItem> get cartItems => List.unmodifiable(_cartItems);

  DateTime _cartUpdatedAt = DateTime.now();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int currentIndex = 0;
List<CommentModel> _comments = [];

List<CommentModel> get comments => _comments;

  Future<void> init() async {
    await loadUserData();
    if (_user != null) {
      await fetchUserCart(_user!.uid);
      await fetchFavorites(_user!.uid);
      _setupCartListener(_user!.uid);
    }
  }

  Future<void> login(User user) async {
    _user = user;
    _token = await user.getIdToken();
    _userId = int.tryParse(user.uid);
    await fetchUserCart(user.uid);
    await fetchFavorites(user.uid);
    _setupCartListener(user.uid);
    notifyListeners();
  }

  void logout() {
    _user = null;
    _token = null;
    _userId = null;
    _cartItems.clear();
    _favoriteItems.clear();
    notifyListeners();
  }

  bool get isLoggedIn => _user != null;

  Future<void> fetchProducts() async {
    try {
      final fetchedProducts = await repository?.fetchProductData();
      if (fetchedProducts != null) {
        products = fetchedProducts;
        notifyListeners();
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
    }
  }

  void setFavorites(List<ProductModel> favorites) {
    _favoriteItems.clear();
    _favoriteItems.addAll(favorites);
    notifyListeners();
  }

  Future<void> toggleFavorite(ProductModel product) async {
    final exists = _favoriteItems.any((item) => item.id == product.id);
    if (exists) {
      _favoriteItems.removeWhere((item) => item.id == product.id);
    } else {
      _favoriteItems.add(product);
    }
    notifyListeners();

    if (_user != null) {
      await updateFavorites(_favoriteItems);
    }
  }

Future<void> updateFavorites(List<ProductModel> favorites) async {
  if (_user == null) {
    debugPrint('No user logged in.');
    return;
  }

  try {
    final jsonList = favorites.map((item) => item.toJson()).toList();
    debugPrint('Favorites to be written: $jsonList');

    await _firestore.collection('users').doc(_user!.uid).set({
      'favorites': jsonList,
    }, SetOptions(merge: true));

    debugPrint('Favorites updated in Firestore');
  } catch (e) {
    debugPrint('Error updating favorites: $e');
  }
}

  double get cartTotal {
    return _cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  }

  void addCartItem(ProductModel product, {int quantity = 1}) {
    final index = _cartItems.indexWhere((item) => item.productId == product.id.toString());
    if (index >= 0) {
      _cartItems[index].quantity += quantity;
    } else {
      _cartItems.add(CartItem(
        id: UniqueKey().toString(),
        productId: product.id.toString(),
        title: product.title ?? 'Unknown product',
        quantity: quantity,
        price: product.price ?? 0.0,
        imageUrl: product.image ?? 'https://via.placeholder.com/150',
      ));
    }
    _cartUpdatedAt = DateTime.now();
    saveCartToPrefs();
    notifyListeners();

    if (_user != null) {
      syncCartToFirebase(_user!.uid);
    }
  }

  void removeCartItem(String productId) {
    _cartItems.removeWhere((item) => item.productId == productId);
    _cartUpdatedAt = DateTime.now();
    notifyListeners();

    if (_user != null) {
      syncCartToFirebase(_user!.uid);
    }
  }

  void incrementQuantity(String productId) {
    final index = _cartItems.indexWhere((item) => item.productId == productId);
    if (index != -1) {
      _cartItems[index].quantity++;
      notifyListeners();
      if (_user != null) {
        syncCartToFirebase(_user!.uid);
      }
    }
  }

  void decrementQuantity(String productId) {
    final index = _cartItems.indexWhere((item) => item.productId == productId);
    if (index != -1 && _cartItems[index].quantity > 1) {
      _cartItems[index].quantity--;
      _cartUpdatedAt = DateTime.now();
      notifyListeners();
      if (_user != null) {
        syncCartToFirebase(_user!.uid);
      }
    }
  }

  Future<List<ProductModel>> _convertApiCartToProducts(List<dynamic> apiCartItems) async {
    final List<ProductModel> result = [];
    for (final item in apiCartItems) {
      try {
        final productId = item['productId'].toString();
        final quantity = int.tryParse(item['quantity'].toString()) ?? 1;

        final product = await repository?.fetchProductById(productId);
        if (product != null) {
          product.count = quantity;
          result.add(product);
        } else {
          debugPrint('Product not found for ID: $productId');
          result.add(ProductModel(
            id: int.tryParse(productId) ?? 0,
            title: 'Product $productId',
            price: 0,
            count: quantity,
          ));
        }
      } catch (e) {
        debugPrint('Error converting cart item: $e');
      }
    }
    return result;
  }
  void setCart(List<ProductModel> products) {
    _cartItems = products.map((product) => CartItem(
      id: UniqueKey().toString(),
      productId: product.id?.toString() ?? '',
      title: product.title ?? 'Unknown',
      quantity: product.count ?? 1,
      price: product.price ?? 0.0,
      imageUrl: product.image ?? 'https://via.placeholder.com/150',
    )).toList();
    notifyListeners();
  }

  Future<void> fetchUserCart(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final cartData = userDoc.data()?['cart'] as List<dynamic>?;
        if (cartData != null) {
          _cartItems = cartData.map((item) => CartItem.fromJson(item)).toList();
          notifyListeners();
          debugPrint('Cart loaded from Firestore: ${_cartItems.length} items');
        }
      } else {
        debugPrint('No cart found in Firestore for user');
      }
    } catch (e) {
      debugPrint('Error fetching cart from Firestore: $e');
    }
  }

  Future<void> saveUserCart(String uid, List<CartItem> cartItems) async {
    final cartData = cartItems.map((item) => item.toJson()).toList();
    await _firestore.collection('users').doc(uid).update({
      'cart': cartData,
    });
  }

  Future<void> fetchFavorites(String userId) async {
    try {
      final result = await repository?.fetchUserFavorites(userId: userId);
      if (result != null) {
        _favoriteItems.clear();
        _favoriteItems.addAll(result.map((item) => ProductModel.fromJson(item)));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching favorites: $e');
    }
  }

  void _setupCartListener(String userId) {
    _firestore.collection('users').doc(userId).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final cartData = snapshot.data()?['cart'] as List<dynamic>?;
        if (cartData != null) {
          _cartItems = cartData.map((item) => CartItem.fromJson(item)).toList();
          notifyListeners();
        }
      }
    });
  }

  Future<void> syncCartToFirebase(String userId) async {
    try {
      await saveUserCart(userId, _cartItems);
      debugPrint('Cart synced to Firestore');
    } catch (e) {
      debugPrint('Error syncing cart: $e');
    }
  }

  Future<void> saveCartToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = jsonEncode(_cartItems.map((item) => item.toJson()).toList());
    await prefs.setString('cart', cartJson);
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final cartString = prefs.getString('cart');
    if (cartString != null) {
      final List<dynamic> cartJson = jsonDecode(cartString);
      _cartItems = cartJson.map((item) => CartItem.fromJson(item)).toList();
      notifyListeners();
    }
  }
  Future<void> updateCart() async {
  if (_user == null) return;
  final now = FieldValue.serverTimestamp();
final cartJson = _cartItems.map((item) => item.toJson()).toList();
print('Cart JSON to be saved: $cartJson');
await FirebaseFirestore.instance
    .collection('users')
    .doc(_user!.uid)
    .set({
  'cart': cartJson,
  'cartUpdatedAt': now,
}, SetOptions(merge: true));

}
Stream<List<CommentModel>> getComments(String productId) {
  return FirebaseFirestore.instance
      .collection('comments')
      .where('productId', isEqualTo: productId)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => CommentModel.fromJson(doc.data())).toList());
}

Future<void> addComment({
  required String productId,
  required String userId,
  required String userName,
  required String content,
}) async {
  await FirebaseFirestore.instance.collection('comments').add({
    'productId': productId,
    'userId': userId,
    'userName': userName,
    'content': content,
  });

  await getComments(productId);
}
}

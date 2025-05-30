import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:shop_app/models/comment.dart';
import 'package:shop_app/models/products.dart';
import 'package:shop_app/services/httpService.dart';


class MyRepository {
  final HttpService httpService;

  MyRepository({required this.httpService});

  Future<List<ProductModel>?> fetchProductData() async {
    try{
      dynamic jsonData = await httpService.getData('products', null);
      List<ProductModel> data = ProductModel.fromList(jsonData);
      return data;
    } catch(e){
      throw Exception('Error fetching product data');
    }
  }

Future<ProductModel?> fetchProductById(String productId) async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .get();

    if (snapshot.exists) {
      final data = snapshot.data();
      return ProductModel.fromJson(data!..['id'] = productId); // Ensure ID is included
    }
  } catch (e) {
    debugPrint('Error fetching product by ID: $e');
  }

  return null;
}


 Future<List<ProductModel>?> getProducts() async {
    try {
      dynamic jsonData = await httpService.getData('products', null);
      List<ProductModel> data = ProductModel.fromList(jsonData);
      return data;
    } catch (e) {
      throw Exception('Error fetching product data');
    }
  }
Future<dynamic> fetchUserCart({required String userId}) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('carts')
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .limit(1)
      .get();

  if (snapshot.docs.isEmpty) return null;

  return snapshot.docs.first.data();
}

  Future<dynamic> syncCart(int? cartId, Map<String, dynamic> cartPayload) async {
    final endpoint = cartId == null ? 'carts' : 'carts/$cartId';

    try {
      if (cartId == null) {
return await httpService.postData(endpoint, null, jsonEncode(cartPayload));
      } else {
return await httpService.putData(endpoint, null, jsonEncode(cartPayload));
      }
    } catch (e) {
      throw Exception('Error syncing cart: $e');
    }
  }
Future<List<Map<String, dynamic>>> fetchUserFavorites({required String userId}) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')  
        .doc(userId)
        .get();

    if (!doc.exists) return [];

    final data = doc.data();
    if (data == null || data['favorites'] == null) return [];

    final favoritesData = data['favorites'] as List<dynamic>;
    return List<Map<String, dynamic>>.from(favoritesData);
  } catch (e) {
    debugPrint('Error fetching favorites: $e');
    return [];
  }
}

Future<void> saveUserCart({required String userId, required Map<String, dynamic> cartPayload}) async {
  try {
    final cartsCollection = FirebaseFirestore.instance.collection('carts');
    final querySnapshot = await cartsCollection.where('userId', isEqualTo: userId).limit(1).get();

    if (querySnapshot.docs.isEmpty) {
      await cartsCollection.add({
        'userId': userId,
        ...cartPayload,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      final docId = querySnapshot.docs.first.id;
      await cartsCollection.doc(docId).update({
        ...cartPayload,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  } catch (e) {
    debugPrint('Error saving cart: $e');
    throw Exception('Failed to save cart');
  }
}

Future<void> saveUserFavorites({
  required String userId,
  required List<Map<String, dynamic>> favorites,
}) async {
  try {
    await FirebaseFirestore.instance
        .collection('favorites')
        .doc(userId)
        .set({
          'items': favorites,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
  } catch (e) {
    debugPrint('Error saving favorites: $e');
  }
}
Future<void> addComment({
  required String productId,
  required String userId,
  required String userName,
  required String content,
}) async {
  final comment = CommentModel(
    productId: productId,
    userId: userId,
    userName: userName,
    content: content,
  );

  await FirebaseFirestore.instance
      .collection('comments')
      .doc(productId)
      .collection('userComments')
      .add(comment.toJson());
}

}

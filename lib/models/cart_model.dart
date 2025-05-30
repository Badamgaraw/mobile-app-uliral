

import 'package:json_annotation/json_annotation.dart';

part 'cart_model.g.dart';

@JsonSerializable()
class CartItem {
  final String id;
  final String productId;
  final String title;
  int quantity;
  final double price;
  final String imageUrl;

  CartItem({
    required this.id,
    required this.productId,
    required this.title,
    this.quantity = 1,
    required this.price,
    required this.imageUrl,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) =>
      _$CartItemFromJson(json);

  Map<String, dynamic> toJson() => _$CartItemToJson(this);

  double get totalPrice => price * quantity;

  static List<CartItem> fromList(List<dynamic> jsonList) {
    return jsonList.map((json) => CartItem.fromJson(json)).toList();
  }
  Map<String, dynamic> get product => {
  'id': productId,
  'title': title,
  'price': price,
  'imageUrl': imageUrl,
};

  get image => null;
Map<String, dynamic> toJsonWithCount() {
  final json = toJson();
  json['count'] = quantity; 
  return json;
}
static CartItem empty() {
    return CartItem(id: '', productId: '', title: '', quantity: 0, price: 0.0, imageUrl: '');
  }
}

@JsonSerializable()
class UserCart {
  final int? userId;
  final List<CartItem> items;
  final DateTime updatedAt;

  UserCart({
    required this.userId,
    required this.items,
    required this.updatedAt,
  });

  factory UserCart.fromJson(Map<String, dynamic> json) =>
      _$UserCartFromJson(json);

  Map<String, dynamic> toJson() => _$UserCartToJson(this);

  double get totalAmount => items.fold(
        0,
        (sum, item) => sum + item.totalPrice,
      );
       void addItem(CartItem item) {
    items.add(item);
  }

  void removeItem(String itemId) {
    items.removeWhere((item) => item.id == itemId);
  }
}

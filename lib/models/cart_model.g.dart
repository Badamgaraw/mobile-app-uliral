// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CartItem _$CartItemFromJson(Map<String, dynamic> json) => CartItem(
      id: json['id'] as String,
      productId: json['productId'] as String,
      title: json['title'] as String,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String,
    );

Map<String, dynamic> _$CartItemToJson(CartItem instance) => <String, dynamic>{
      'id': instance.id,
      'productId': instance.productId,
      'title': instance.title,
      'quantity': instance.quantity,
      'price': instance.price,
      'imageUrl': instance.imageUrl,
    };

UserCart _$UserCartFromJson(Map<String, dynamic> json) => UserCart(
      userId: (json['userId'] as num?)?.toInt(),
      items: (json['items'] as List<dynamic>)
          .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$UserCartToJson(UserCart instance) => <String, dynamic>{
      'userId': instance.userId,
      'items': instance.items,
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

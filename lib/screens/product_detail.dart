import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/models/comment.dart';
import 'package:shop_app/models/products.dart';
import 'package:shop_app/provider/globalProvider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Product_detail extends StatefulWidget {
  final ProductModel product;
  const Product_detail(this.product, {super.key});

  @override
  State<Product_detail> createState() => _Product_detailState();
}

class _Product_detailState extends State<Product_detail> {
  final TextEditingController _commentController = TextEditingController();
  final _user = FirebaseAuth.instance.currentUser;

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
  }
  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Consumer<Global_provider>(
      builder: (context, provider, child) {
        final isFavorite = provider.favoriteItems.any((p) => p.id == product.id);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Product detail'),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.network(product.image!, height: 200),
                  const SizedBox(height: 8),
                  Text(product.title!,
                      style:
                          const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(product.description!,
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('PRICE: \$${product.price}',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('Rating: ${product.count}',
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 20),

                  const Text("Сэтгэгдлүүд:",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  StreamBuilder<List<CommentModel>>(
                    stream: getComments(product.id.toString()),
                    
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Text('Одоогоор сэтгэгдэл алга байна.');
                      }

                      final comments = snapshot.data!;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          return ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(comment.userName),
                            subtitle: Text(comment.content),
                            
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                  TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Сэтгэгдэл бичих...',
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      if (_commentController.text.isNotEmpty && _user != null) {
                        await addComment(
                          productId: product.id.toString(),
                          userId: _user!.uid,
                          userName:  _user!.email ?? "user",
                          content: _commentController.text.trim(),
                        );
                        _commentController.clear();
                        setState(() {});
                      }
                    },
                    child: const Text("Сэтгэгдэл илгээх"),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FloatingActionButton(
                heroTag: 'cart',
                onPressed: () async {
                  provider.addCartItem(product);
                  await provider.updateCart();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Added to cart')),
                  );
                },
                tooltip: 'Add to Cart',
                child: const Icon(Icons.shopping_cart),
              ),
              const SizedBox(height: 16),
              FloatingActionButton(
                heroTag: 'favorite',
                onPressed: () async {
                  provider.toggleFavorite(product);
                  await provider.updateFavorites(provider.favoriteItems);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isFavorite
                            ? 'Removed from favorites'
                            : 'Added to favorites',
                      ),
                    ),
                  );
                },
                tooltip: 'Toggle Favorite',
                child: Icon(
                  Icons.favorite,
                  color: isFavorite ? Colors.red : Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

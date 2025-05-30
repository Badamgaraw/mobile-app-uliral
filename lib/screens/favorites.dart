import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/models/products.dart';
import 'package:shop_app/provider/globalProvider.dart'; 

class Favorites extends StatelessWidget {
  const Favorites({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<Global_provider>(
      builder: (context, provider, child) {
        final favorites = provider.favoriteItems;

        if (favorites.isEmpty) {
          return const Center(
            child: Text(
              'Та дуртай бүтээгдэхүүнээ нэмээгүй байна.',
              style: TextStyle(fontSize: 18),
            ),
          );
        }

        return ListView.builder(
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            final product = favorites[index];

            return ListTile(
              leading: product.image != null
                  ? Image.network(
                      product.image!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image),
                    )
                  : const Icon(Icons.image_not_supported),
              title: Text(product.title ?? 'No title'),
              subtitle: Text('\$${(product.price ?? 0).toStringAsFixed(2)}'),
              trailing: IconButton(
                icon: const Icon(Icons.favorite, color: Colors.red),
                onPressed: () async {
                  final newFavorites = List<ProductModel>.from(favorites)
                    ..removeWhere((item) => item.id == product.id);
                  await provider.updateFavorites(newFavorites);
                },
              ),
            );
          },
        );
      },
    );
  }
}

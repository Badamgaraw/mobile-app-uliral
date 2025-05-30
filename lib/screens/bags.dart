import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/models/cart_model.dart';
import 'package:shop_app/provider/globalProvider.dart';

class Basket extends StatefulWidget {
  const Basket({Key? key}) : super(key: key);

  @override
  State<Basket> createState() => _BasketState();
}

class _BasketState extends State<Basket> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await Provider.of<Global_provider>(context, listen: false)
            .fetchUserCart(user.uid);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Сагс ачаалахад алдаа гарлаа: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Global_provider>(builder: (context, provider, child) {
      final cartItems = provider.cartItems;
      debugPrint('Cart items count: ${cartItems.length}');
      final total = cartItems.fold<double>(
        0,
        (sum, item) => sum + (item.price ?? 0) * item.quantity,
      );

      return Scaffold(
        appBar: AppBar(
          title: const Text('Сагс'),
          actions: [
            if (cartItems.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _clearCart(provider),
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : cartItems.isEmpty
                ? const Center(
                    child: Text(
                      "Сагс хоосон байна.",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                    ),
                  )
                : ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return Dismissible(
                        key: ValueKey(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) async {
                           provider.removeCartItem(item.productId);
                        },
                        child: ListTile(
                          leading: Image.network(
                            item.imageUrl ?? '',
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image),
                          ),
                          title: Text(item.title ?? 'No title'),
                          subtitle: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () {
                                      if (item.quantity > 1) {
                                        provider.decrementQuantity(item.productId);
                                      } else {
                                        provider.removeCartItem(item.productId);
                                      }
                                    },
                                  ),
                                  Text('${item.quantity}'),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () =>
                                        provider.incrementQuantity(item.productId),
                                  ),
                                ],
                              ),
                              Text(
                                '\$${(item.price ?? 0).toStringAsFixed(2)} x ${item.quantity}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
        bottomNavigationBar: cartItems.isEmpty
            ? null
            : BottomAppBar(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Нийт: \$${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _checkout(context, provider),
                        child: const Text('Захиалах'),
                      ),
                    ],
                  ),
                ),
              ),
      );
    });
  }

  Future<void> _clearCart(Global_provider provider) async {
    try {
      setState(() => _isLoading = true);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        provider.cartItems.clear();
        await provider.syncCartToFirebase(user.uid);
        await provider.saveCartToPrefs();
        provider.notifyListeners();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Сагс цэвэрлэхэд алдаа гарлаа: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkout(BuildContext context, Global_provider provider) async {
    try {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(seconds: 1));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Захиалга амжилттай хийгдлээ!')),
      );
      await _clearCart(provider);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Захиалга хийхэд алдаа гарлаа: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
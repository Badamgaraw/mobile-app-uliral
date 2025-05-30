import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/models/cart_model.dart';
import 'package:shop_app/models/products.dart';
import 'package:shop_app/provider/globalProvider.dart';
import 'package:shop_app/screens/bags.dart';
import 'package:shop_app/screens/favorites.dart';
import 'package:shop_app/screens/profile.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  final List<ProductModel> products;
  final List<CartItem> cartItems;

  const HomePage({
    Key? key,
    required this.products,
    required this.cartItems,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
 bool _isLoading = true;
  @override
  
  void initState() {
    super.initState();
    _initUser();
  }

  Future<void> _initUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final provider = Provider.of<Global_provider>(context, listen: false);
      provider.login(user);
      await provider.fetchUserCart(user.uid);
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
final appState = Provider.of<Global_provider>(context);   
    return const SizedBox();
  }
}

class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  int _calculateIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/bag')) return 1;
    if (location.startsWith('/favorite')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _calculateIndex(context);
    final appState = Provider.of<Global_provider>(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.blue,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
          selectedIconTheme: IconThemeData(color: Colors.white, size: 24), // Active icon
  unselectedIconTheme: IconThemeData(color: Colors.white70, size: 22),
        currentIndex: index,
         type: BottomNavigationBarType.fixed,
        onTap: (selectedIndex) {
          switch (selectedIndex) {
            case 0:
              context.go('/shop');
              break;
            case 1:
              context.go('/bag');
              break;
            case 2:
              context.go('/favorite');
              break;
            case 3:
              if (appState.isLoggedIn) {
                context.go('/profile');
              } else {
                context.go('/login'); 
              }
              break;
          }
        },
        
        items: [
        
          BottomNavigationBarItem(icon: Icon(Icons.shop), label: 'shop'.tr()),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'bag'.tr()),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'favorite'.tr()),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'profile'.tr()),
        ],
      ),
    );
  }
}

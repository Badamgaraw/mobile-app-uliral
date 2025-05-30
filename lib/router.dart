
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/provider/globalProvider.dart';
import 'package:shop_app/screens/bags.dart';
import 'package:shop_app/screens/favorites.dart';
import 'package:shop_app/screens/login_page.dart';
import 'package:shop_app/screens/profile.dart';
import 'package:shop_app/screens/shopping.dart';
import 'package:shop_app/home.dart';
import 'package:shop_app/screens/sign_page.dart'; 

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey, 
  initialLocation: '/shop',
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(
          path: '/shop',
          builder: (context, state) => const ShopPage(products: [],),
        ),
        GoRoute(
          path: '/bag',
          builder: (context, state) => const Basket(),
        ),
        GoRoute(
          path: '/favorite',
          builder: (context, state) => const Favorites(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) {
            final provider = Provider.of<Global_provider>(context, listen: false);
            final user = provider.user;
            final isLoggedIn = user != null;
            if (isLoggedIn) {
              return Profile(
                email: user!.email ?? 'No Email',
                onLogout: () {
                  provider.logout();
                  context.go('/login');
                },
              );
            } else {
              Future.microtask(() => context.go('/login'));
              return const SizedBox(); 
            }
          },
        ),
      ],
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/sign-in',
      builder: (context, state) => const SignInPage(),  
    ),
  ],
);

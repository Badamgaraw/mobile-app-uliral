import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/firebase_notification.dart';
import 'package:shop_app/firebase_options.dart';
import 'package:shop_app/global_keys.dart';
import 'package:shop_app/home.dart';
import 'package:shop_app/provider/globalProvider.dart';
import 'package:shop_app/screens/login_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shop_app/repository/repository.dart';
import 'package:shop_app/services/httpService.dart';
import 'locale_storage.dart';
import 'package:shop_app/router.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  final savedLocale = await LocaleStorage.getSavedLocale();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseMessage().initNotification();
  runApp(
    MultiProvider(
      providers: [
        Provider<HttpService>(
          create: (_) => HttpService(baseUrl: "https://fakestoreapi.com"),
        ),
        ProxyProvider<HttpService, MyRepository>(
          update: (_, httpService, __) => MyRepository(httpService: httpService),
        ),
        ChangeNotifierProvider(
          create: (context) => Global_provider(
            Provider.of<MyRepository>(context, listen: false),
          ),
        ),
      ],
      child: EasyLocalization(
        supportedLocales: [Locale('en', 'US'), Locale('mn', 'MN')],
        path: 'assets/translations',
        fallbackLocale: Locale('en', 'US'),
        startLocale: savedLocale,
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: appRouter,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData(useMaterial3: false),
    );
  }
}


class AppWithCartLoader extends StatefulWidget {
  const AppWithCartLoader({super.key});

  @override
  State<AppWithCartLoader> createState() => _AppWithCartLoaderState();
}

class _AppWithCartLoaderState extends State<AppWithCartLoader> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeApp());
  }

Future<void> _initializeApp() async {
  final user = FirebaseAuth.instance.currentUser;
  try {
    final globalProvider = Provider.of<Global_provider>(context, listen: false);
    
    await globalProvider.loadUserData();

    if (globalProvider.token != null && globalProvider.userId != null) {
      if (globalProvider.cartItems.isEmpty) {
        await globalProvider.fetchUserCart(user!.uid);
      }
      if (globalProvider.favoriteItems.isEmpty) {
        await globalProvider.fetchFavorites(user!.uid);
      }
    }
  } catch (e) {
    debugPrint('Error initializing app: $e');
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}


 @override
Widget build(BuildContext context) {
  if (_isLoading) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }

  final globalProvider = Provider.of<Global_provider>(context, listen: false);
  final isLoggedIn = globalProvider.user != null;

  if (isLoggedIn) {
    return HomePage(
      products: globalProvider.products,
      cartItems: globalProvider.cartItems,
    );
  } else {
    return const LoginPage();
  }
}

}

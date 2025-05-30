import 'package:flutter/material.dart';
import 'package:shop_app/global_keys.dart';
import 'package:easy_localization/easy_localization.dart';

class Profile extends StatelessWidget {
  final String email;
  final VoidCallback onLogout;

  const Profile({
    super.key,
    required this.email,
    required this.onLogout,
  });

  void changeLanguage() {
    final contxt = GlobalKeys.navigatorKey.currentContext!;
    if (contxt.locale.languageCode == Locale('mn', 'MN').languageCode) {
      contxt.setLocale(const Locale('en', 'US'));
    } else {
      contxt.setLocale(const Locale('mn', 'MN'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton(
            onPressed: changeLanguage,
            child: Text('Хэл солих'),
          ),
          const SizedBox(height: 20),
          Text(
            'Username: $email',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 8),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: onLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }
}

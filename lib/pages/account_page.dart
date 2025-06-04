import 'package:flutter/material.dart';

/// Purpose: Displays account information and provides a logout option.
/// References:
/// - `HomePage`: Navigates to this page for account management.
class AccountPage extends StatelessWidget {
  final String username;
  final VoidCallback onLogout;
  const AccountPage({
    required this.username,
    required this.onLogout,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Eingeloggt als:', style: TextStyle(color: Colors.white)),
          const SizedBox(height: 4),
          Text(
            username,
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onLogout, child: const Text('Abmelden')),
        ],
      ),
    );
  }
}

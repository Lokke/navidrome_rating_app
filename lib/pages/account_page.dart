import 'package:flutter/material.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';

import '../services/logging_service.dart';

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
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              // Retrieve logs and allow sharing
              final paths = await LoggingService.instance.getSessionLogPaths();
              // Convert to XFile for sharing
              final xfiles =
                  paths
                      .where((p) => File(p).existsSync())
                      .map((p) => XFile(p))
                      .toList();
              if (xfiles.isNotEmpty) {
                await Share.shareXFiles(
                  xfiles,
                  text: 'App-Logs der letzten Sitzungen',
                );
              }
            },
            child: const Text('Logs teilen'),
          ),
        ],
      ),
    );
  }
}

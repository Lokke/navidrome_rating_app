import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../services/navidrome_service.dart';
import '../services/player_manager.dart';
import 'rating_page.dart';
import 'search_page.dart';
import 'account_page.dart';
import '../widgets/floating_bar.dart';

class HomePage extends StatefulWidget {
  final String username;
  final String password;
  final VoidCallback onLogout;
  const HomePage({
    required this.username,
    required this.password,
    required this.onLogout,
    super.key,
  });
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  late final service = NavidromeService(
    baseUrl: 'https://musik.radio-endstation.de',
    username: widget.username,
    password: widget.password,
  );

  // Use the singleton player
  AudioPlayer get _player => PlayerManager().player;

  @override
  void dispose() {
    // No need to dispose the singleton player here
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      RatingPage(
        username: widget.username,
        password: widget.password,
        player: _player,
      ),
      SearchPage(service: service, player: _player),
      AccountPage(username: widget.username, onLogout: widget.onLogout),
    ];
    return Scaffold(
      body: Stack(
        children: [
          pages[_currentIndex],
          Positioned(
            left: 5,
            right: 5,
            bottom: kBottomNavigationBarHeight + 5,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.black87,
              ),
              child: FloatingBar(player: _player),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Theme.of(context).colorScheme.secondary,
        unselectedItemColor: Colors.grey,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Bewerten'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Suche'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }
}

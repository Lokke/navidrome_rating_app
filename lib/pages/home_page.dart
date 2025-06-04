import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import '../services/navidrome_service.dart';
import '../services/player_manager.dart';
import 'rating_page.dart';
import 'search_page.dart';
import 'account_page.dart';
import 'rating2_page.dart';
import '../widgets/floating_bar.dart';
import 'now_playing_view.dart';

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

  final PanelController _panelController = PanelController();

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
    // Wrap content in SlidingUpPanel for draggable NowPlayingPage
    return SlidingUpPanel(
      controller: _panelController,
      panel: NowPlayingPage(
        player: _player,
        service: service,
        onClose: () => _panelController.close(),
      ),
      minHeight: 0,
      maxHeight: MediaQuery.of(context).size.height * 0.9,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      body: Scaffold(
        body: Stack(
          children: [
            pages[_currentIndex],
            Positioned(
              left: 5,
              right: 5,
              bottom: kBottomNavigationBarHeight + 5,
              child: GestureDetector(
                onTap: () => _panelController.open(),
                child: FloatingBar(player: _player, service: service),
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
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(
                        'https://example.com/your_profile_picture.jpg',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                title: const Text('Bewerten'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _currentIndex = 0;
                  });
                },
              ),
              ListTile(
                title: const Text('Suche'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _currentIndex = 1;
                  });
                },
              ),
              ListTile(
                title: const Text('Account'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _currentIndex = 2;
                  });
                },
              ),
              ListTile(
                title: const Text('Rating2 Page'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => Rating2Page(
                            username: widget.username,
                            password: widget.password,
                            player: _player,
                          ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';

void main() async {
  debugPrint('App starting in main()');
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('Flutter binding initialized');
  runApp(const MyApp());
  debugPrint('MyApp widget launched');
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool checking = true;
  bool loggedIn = false;
  String? username;
  String? password;

  @override
  void initState() {
    super.initState();
    _checkLogin();
    // Fallback: stop showing spinner after 5s if still checking
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && checking) {
        setState(() {
          checking = false;
        });
      }
    });
  }

  Future<void> _checkLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final u = prefs.getString('username');
      final p = prefs.getString('password');
      if (u != null && p != null) {
        final service = NavidromeService(
          baseUrl: 'https://musik.radio-endstation.de',
          username: u,
          password: p,
        );
        final ok = await service.ping();
        if (ok) {
          setState(() {
            loggedIn = true;
            username = u;
            password = p;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Login check error: $e');
    } finally {
      setState(() {
        checking = false;
        if (!loggedIn) loggedIn = false;
      });
    }
  }

  void _onLogin(String u, String p) {
    setState(() {
      loggedIn = true;
      username = u;
      password = p;
    });
  }

  void _onLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('password');
    setState(() {
      loggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (checking)
      return MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    return MaterialApp(
      title: 'Navidrome Rating',
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: Color(0xFFB71C1C), // deep red
          secondary: Color(0xFFFF5722), // orange accent
        ),
        scaffoldBackgroundColor: Color(0xFF121212),
        cardColor: Color(0xFF1E1E1E),
        textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFFF5722),
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home:
          loggedIn
              ? HomePage(
                username: username!,
                password: password!,
                onLogout: _onLogout,
              )
              : LoginPage(onLogin: _onLogin),
    );
  }
}

class Playlist {
  final String id;
  final String name;
  final bool isPublic;
  final String owner;
  Playlist({
    required this.id,
    required this.name,
    required this.isPublic,
    required this.owner,
  });
}

class Song {
  final String id;
  final String title;
  final String artist;
  final String coverUrl;
  int rating;
  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.coverUrl,
    this.rating = 0,
  });
}

class NavidromeService {
  final String baseUrl;
  final String username;
  final String password;
  final String client = 'NavidromeRatingApp';
  final String apiVersion = '1.16.1';

  NavidromeService({
    required this.baseUrl,
    required this.username,
    required this.password,
  });

  Uri _uri(String endpoint, [Map<String, String>? extra]) {
    final params = <String, String>{
      'u': username,
      'p': password,
      'v': apiVersion,
      'c': client,
      'f': 'json', // request JSON format
    };
    if (extra != null) params.addAll(extra);
    // ensure .view suffix for Subsonic endpoints if missing
    final path = endpoint.endsWith('.view') ? endpoint : endpoint + '.view';
    return Uri.parse('$baseUrl$path').replace(queryParameters: params);
  }

  Future<bool> ping() async {
    final response = await http.get(_uri('/rest/ping'));
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final status = data['subsonic-response']['status'] as String?;
    return status == 'ok';
  }

  Future<List<Song>> searchSongs(String query) async {
    final response = await http.get(
      _uri('/rest/search2', {'query': query, 'type': 'music'}),
    );
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final songsJson =
        data['subsonic-response']['searchResult2']['song'] as List<dynamic>;
    return songsJson.map((e) {
      final id = e['id'] as String;
      final title = e['title'] as String;
      final artist = e['artist'] as String;
      final coverArtId = e['coverArt']?.toString();
      final coverUrl =
          coverArtId != null
              ? _uri('/rest/getCoverArt', {
                'id': coverArtId,
                'size': '500',
              }).toString()
              : '';
      return Song(id: id, title: title, artist: artist, coverUrl: coverUrl);
    }).toList();
  }

  Future<void> setRating(String id, int rating) async {
    await http.get(
      _uri('/rest/setRating', {'id': id, 'rating': rating.toString()}),
    );
  }

  Future<List<Playlist>> getPlaylists() async {
    final response = await http.get(_uri('/rest/getPlaylists'));
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final list =
        data['subsonic-response']['playlists']['playlist'] as List<dynamic>;
    return list
        .map(
          (e) => Playlist(
            id: e['id'] as String,
            name: e['name'] as String,
            isPublic: e['public'] as bool,
            owner: e['owner'] as String,
          ),
        )
        .toList();
  }

  Future<List<Song>> getPlaylistSongs(String playlistId) async {
    final response = await http.get(
      _uri('/rest/getPlaylist', {'id': playlistId}),
    );
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    debugPrint('getPlaylistSongs JSON: ' + jsonEncode(data));
    final sr = data['subsonic-response'] as Map<String, dynamic>?;
    if (sr == null)
      throw Exception('Ungültige API-Antwort: kein subsonic-response');
    // Determine playlist node, handling both 'playlist' and 'playlists'
    dynamic plData =
        sr['playlist'] ??
        (sr['playlists'] as Map<String, dynamic>?)?['playlist'];
    if (plData == null)
      throw Exception('Ungültige API-Antwort: kein playlist Objekt');
    // If list of playlists, find matching id
    if (plData is List) {
      plData = plData.firstWhere(
        (p) => p['id'] == playlistId,
        orElse: () => throw Exception('Playlist nicht gefunden'),
      );
    }
    // Now plData should be a Map representing one playlist
    final plNode = plData as Map<String, dynamic>;
    // Extract entries: could be under 'entry' directly or inside plNode
    dynamic entryNode =
        plNode['entry'] ??
        (plNode['entries'] as Map<String, dynamic>?)?['entry'];
    if (entryNode == null)
      throw Exception('Ungültige API-Antwort: kein entry Feld');
    List<dynamic> entries = entryNode is List ? entryNode : [entryNode];
    debugPrint('Parsed ${entries.length} entries');
    return entries.map((e) {
      final id = e['id'] as String;
      final title = e['title'] as String;
      final artist = e['artist'] as String;
      final coverArtId = e['coverArt']?.toString();
      final coverUrl =
          coverArtId != null
              ? _uri('/rest/getCoverArt', {
                'id': coverArtId,
                'size': '500',
              }).toString()
              : '';
      final rating = (e['rating'] as int?) ?? 0;
      return Song(
        id: id,
        title: title,
        artist: artist,
        coverUrl: coverUrl,
        rating: rating,
      );
    }).toList();
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onLogin});
  final void Function(String username, String password) onLogin;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _userController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: _passController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 16),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        _loading = true;
                        _error = null;
                      });
                      final u = _userController.text;
                      final p = _passController.text;
                      final service = NavidromeService(
                        baseUrl: 'https://musik.radio-endstation.de',
                        username: u,
                        password: p,
                      );
                      final ok = await service.ping();
                      if (ok) {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('username', u);
                        await prefs.setString('password', p);
                        widget.onLogin(u, p);
                      } else {
                        setState(() {
                          _error = 'Zugangsdaten ungültig';
                          _loading = false;
                        });
                      }
                    },
                    child: const Text('Login'),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class RatingPage extends StatefulWidget {
  const RatingPage({super.key, required this.username, required this.password});
  final String username;
  final String password;
  @override
  State<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  late final service = NavidromeService(
    baseUrl: 'https://musik.radio-endstation.de',
    username: widget.username,
    password: widget.password,
  );
  final AudioPlayer _player = AudioPlayer();
  final PageController _pageController = PageController();
  List<Song> songs = [];
  int currentIndex = 0;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    // Sync carousel on sequence changes before loading tracks
    _player.sequenceStateStream.listen((seqState) {
      final idx = seqState?.currentIndex ?? 0;
      if (idx != currentIndex) {
        setState(() => currentIndex = idx);
        _pageController.animateToPage(
          idx,
          duration: const Duration(milliseconds: 300),
          curve: Curves.ease,
        );
      }
    });
    _loadSongs();
  }

  @override
  void dispose() {
    _player.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadSongs() async {
    try {
      final playlists = await service.getPlaylists();
      final myPlaylist = playlists.firstWhere(
        (p) =>
            p.owner == widget.username &&
            !p.isPublic &&
            p.name.contains('Hausaufgaben'),
      );
      final allSongs = await service.getPlaylistSongs(myPlaylist.id);
      final unrated = allSongs.where((s) => s.rating == 0).toList();
      songs = unrated;
      await _initAudio();
      setState(() {
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Fehler: ${e.toString()}';
        loading = false;
      });
    }
  }

  Future<void> _initAudio() async {
    // Buffer only current and next song
    final initialCount = songs.length >= 1 ? 1 : songs.length;
    final initialSources =
        songs.take(initialCount).map((song) {
          final url = service._uri('/rest/stream', {'id': song.id});
          return AudioSource.uri(url);
        }).toList();
    final playlistSource = ConcatenatingAudioSource(children: initialSources);
    await _player.setAudioSource(playlistSource);
    // preload additional when nearing end
    _player.currentIndexStream.listen((idx) async {
      if (idx == null) return;
      final totalBuffered =
          (_player.audioSource as ConcatenatingAudioSource).length;
      // Preload next song when reaching the end of buffer (only one ahead)
      if (idx + 1 >= totalBuffered && totalBuffered < songs.length) {
        final nextSong = songs[totalBuffered];
        final nextSource = AudioSource.uri(
          service._uri('/rest/stream', {'id': nextSong.id}),
        );
        await (_player.audioSource as ConcatenatingAudioSource).add(nextSource);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (error != null) return Scaffold(body: Center(child: Text(error!)));
    if (songs.isEmpty)
      return const Scaffold(
        body: Center(child: Text('Keine unbewerteten Lieder gefunden.')),
      );
    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        itemCount: songs.length,
        onPageChanged: (index) {
          setState(() => currentIndex = index);
          _player.seek(Duration.zero, index: index);
          _player.play();
        },
        itemBuilder: (context, idx) {
          final song = songs[idx];
          return Center(
            child: Card(
              margin: const EdgeInsets.all(8),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (_player.playing) {
                          _player.pause();
                        } else {
                          _player.play();
                        }
                      },
                      child: Image.network(
                        song.coverUrl,
                        width: 300,
                        height: 300,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      song.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(song.artist, style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 8),
                    RatingBar.builder(
                      initialRating: song.rating.toDouble(),
                      minRating: 1,
                      direction: Axis.horizontal,
                      allowHalfRating: false,
                      itemCount: 5,
                      itemSize: 32,
                      unratedColor: Colors.grey.shade600,
                      itemBuilder:
                          (context, _) => Icon(
                            Icons.star,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                      onRatingUpdate: (rating) async {
                        await service.setRating(song.id, rating.toInt());
                        setState(() {
                          song.rating = rating.toInt();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    // Playback progress bar
                    StreamBuilder<Duration?>(
                      stream: _player.durationStream,
                      builder: (context, durSnap) {
                        final duration = durSnap.data ?? Duration.zero;
                        return StreamBuilder<Duration>(
                          stream: _player.positionStream,
                          builder: (context, posSnap) {
                            final position = posSnap.data ?? Duration.zero;
                            return Column(
                              children: [
                                // Interactive progress slider
                                Slider(
                                  min: 0,
                                  max:
                                      duration.inMilliseconds > 0
                                          ? duration.inMilliseconds.toDouble()
                                          : 1.0,
                                  value:
                                      position.inMilliseconds
                                          .clamp(0, duration.inMilliseconds)
                                          .toDouble(),
                                  activeColor:
                                      Theme.of(context).colorScheme.secondary,
                                  inactiveColor: Colors.grey.shade800,
                                  onChanged:
                                      (value) => _player.seek(
                                        Duration(milliseconds: value.toInt()),
                                      ),
                                ),
                                // Time labels
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(position),
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    Text(
                                      _formatDuration(duration),
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Add helper below _RatingPageState
String _formatDuration(Duration d) {
  final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$mm:$ss';
}

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
  @override
  Widget build(BuildContext context) {
    final pages = [
      RatingPage(username: widget.username, password: widget.password),
      SearchPage(service: service),
      AccountPage(username: widget.username, onLogout: widget.onLogout),
    ];
    return Scaffold(
      body: pages[_currentIndex],
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

class SearchPage extends StatefulWidget {
  final NavidromeService service;
  const SearchPage({required this.service, super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _query = '';
  List<Song> _results = [];
  bool _loading = false;
  Future<void> _search() async {
    if (_query.isEmpty) return;
    setState(() => _loading = true);
    _results = await widget.service.searchSongs(_query);
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Suchbegriff',
              prefixIcon: Icon(Icons.search),
            ),
            style: const TextStyle(color: Colors.white),
            onChanged: (v) => _query = v,
            onSubmitted: (_) => _search(),
          ),
          const SizedBox(height: 8),
          _loading
              ? const CircularProgressIndicator()
              : Expanded(
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (c, i) {
                    final song = _results[i];
                    return ListTile(
                      leading:
                          song.coverUrl.isNotEmpty
                              ? Image.network(
                                song.coverUrl,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              )
                              : const Icon(Icons.music_note),
                      title: Text(
                        song.title,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        song.artist,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
        ],
      ),
    );
  }
}

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

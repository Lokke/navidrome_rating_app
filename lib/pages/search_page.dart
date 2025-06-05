import 'package:flutter/cupertino.dart';
import 'package:just_audio/just_audio.dart';
import '../services/navidrome_service.dart';
import '../services/playback_manager.dart';
import '../services/song_download_service.dart';
import '../widgets/song_list_tile.dart';
import '../models/song.dart';
import '../utils/app_colors.dart';

class SearchPage extends StatefulWidget {
  final NavidromeService service;
  final AudioPlayer player;
  const SearchPage({required this.service, required this.player, super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _query = '';
  List<Song> _results = [];
  bool _loading = false;

  late final playbackManager = PlaybackManager(
    player: widget.player,
    service: widget.service,
  );
  late final songDownloadService = SongDownloadService(widget.service);

  Future<void> _search() async {
    if (_query.isEmpty) return;
    setState(() => _loading = true);
    final results = await widget.service.searchSongs(_query);
    for (var song in results) {
      final rating = await widget.service.getRating(song.id);
      song.rating = rating;
    }
    // Sort by rating descending (highest rating first)
    results.sort((a, b) => b.rating.compareTo(a.rating));
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            CupertinoSearchTextField(
              placeholder: 'Suchbegriff',
              backgroundColor: CupertinoColors.secondarySystemFill,
              style: const TextStyle(color: CupertinoColors.white),
              prefixIcon: const Icon(
                CupertinoIcons.search,
                color: CupertinoColors.white,
              ),
              onChanged: (v) {
                _query = v;
                _search();
              },
            ),
            const SizedBox(height: 8),
            _loading
                ? const CupertinoActivityIndicator()
                : Expanded(
                  child: ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (c, i) {
                      final song = _results[i];
                      return Row(
                        children: [
                          Expanded(
                            child: SongListTile(
                              song: song,
                              onTap: () {
                                // Use playlist mode for immediate streaming
                                playbackManager.playPlaylist(
                                  _results,
                                  startIndex: i,
                                );
                              },
                            ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            child: Icon(
                              CupertinoIcons.ellipsis,
                              color: AppColors.secondary,
                            ),
                            onPressed: () {
                              showCupertinoModalPopup(
                                context: context,
                                builder:
                                    (_) => CupertinoActionSheet(
                                      title: Text(song.title),
                                      actions: [
                                        CupertinoActionSheetAction(
                                          child: const Text(
                                            'Als nächstes hinzufügen',
                                          ),
                                          onPressed: () {
                                            playbackManager.addSongToQueue(
                                              song,
                                              next: true,
                                            );
                                            Navigator.pop(context);
                                          },
                                        ),
                                        CupertinoActionSheetAction(
                                          child: const Text(
                                            'Ans Ende hinzufügen',
                                          ),
                                          onPressed: () {
                                            playbackManager.addSongToQueue(
                                              song,
                                              next: false,
                                            );
                                            Navigator.pop(context);
                                          },
                                        ),
                                      ],
                                      cancelButton: CupertinoActionSheetAction(
                                        isDefaultAction: true,
                                        child: const Text('Abbrechen'),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                    ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

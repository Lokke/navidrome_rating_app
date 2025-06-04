// Purpose: Represents a song fetched from the Navidrome API.
// Contains metadata like ID, title, artist, cover URL, and user rating.
// References:
// - Used by `NavidromeService` to fetch songs and ratings.
// - Used by `PlaybackManager` for playback.

class Song {
  final String id;
  final String title;
  final String artist;
  final String coverUrl;
  final String mediaId;
  int rating;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.coverUrl,
    required this.mediaId,
    this.rating = 0,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      coverUrl:
          json['coverArt'] != null
              ? 'https://musik.radio-endstation.de/rest/getCoverArt?id=${json['coverArt']}'
              : '',
      mediaId: json['mediaId'] as String,
      rating: json['userRating'] as int? ?? 0,
    );
  }
}

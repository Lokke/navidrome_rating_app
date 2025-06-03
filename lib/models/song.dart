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

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      coverUrl:
          json['coverArt'] != null
              ? 'https://musik.radio-endstation.de/rest/getCoverArt?id=${json['coverArt']}'
              : '',
      rating: json['userRating'] as int? ?? 0,
    );
  }
}

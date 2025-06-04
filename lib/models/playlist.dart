// Purpose: Represents a playlist fetched from the Navidrome API.
// Contains basic information like ID, name, visibility, and owner.
// References:
// - Used by `NavidromeService` to fetch playlists.

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

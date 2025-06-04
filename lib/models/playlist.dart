/*
 * File: playlist.dart
 * ------------------
 * Defines the Playlist model representing a Navidrome playlist.
 * Fields:
 * - id: Unique playlist identifier.
 * - name: Playlist name.
 * - isPublic: Visibility flag.
 * - owner: Username of the playlist owner.
 */

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

import 'package:flutter/cupertino.dart';
import '../models/song.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class SongListTile extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;

  const SongListTile({required this.song, required this.onTap, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Cover image
            song.coverUrl.isNotEmpty
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    song.coverUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) => Container(
                          width: 40,
                          height: 40,
                          color: CupertinoColors.secondarySystemFill,
                        ),
                  ),
                )
                : Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: CupertinoColors.secondarySystemFill,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            const SizedBox(width: 12),
            // Title and artist
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.artist,
                    style: const TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Rating stars on the right
            RatingBarIndicator(
              rating: song.rating.toDouble(),
              itemCount: 5,
              itemSize: 16,
              direction: Axis.horizontal,
              unratedColor: CupertinoColors.systemGrey2,
              itemBuilder:
                  (context, _) => const Icon(
                    CupertinoIcons.star_fill,
                    color: CupertinoColors.activeBlue,
                    size: 16,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

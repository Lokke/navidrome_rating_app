import 'package:flutter/material.dart';
import '../models/song.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class SongListTile extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;

  const SongListTile({required this.song, required this.onTap, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading:
          song.coverUrl.isNotEmpty
              ? Image.network(
                song.coverUrl,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 40,
                    height: 40,
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withOpacity(0.3),
                  );
                },
              )
              : Container(
                width: 40,
                height: 40,
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
              ),
      title: Text(song.title, style: const TextStyle(color: Colors.white)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(song.artist, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 4),
          RatingBarIndicator(
            rating: song.rating.toDouble(),
            itemCount: 5,
            itemSize: 16,
            direction: Axis.horizontal,
            unratedColor: Colors.grey.shade600,
            itemBuilder:
                (context, _) => Icon(
                  Icons.star,
                  color: Theme.of(context).colorScheme.secondary,
                ),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

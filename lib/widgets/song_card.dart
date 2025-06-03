import 'package:flutter/material.dart';
import '../models/song.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class SongCard extends StatelessWidget {
  final Song song;
  final void Function(double rating) onRatingUpdate;

  const SongCard({required this.song, required this.onRatingUpdate, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {},
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
                onRatingUpdate: onRatingUpdate,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

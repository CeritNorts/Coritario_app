import 'package:flutter/material.dart';
import 'package:coritario_app/models/song.dart';
import 'package:coritario_app/screens/song_screen.dart';

class ArtistSongsScreen extends StatelessWidget {
  final String artistName;
  final List<Song> songs;

  const ArtistSongsScreen({
    super.key,
    required this.artistName,
    required this.songs,
  });

  @override
  Widget build(BuildContext context) {
    // Ordenamiento
    List<Song> sortedSongs = List.from(songs);
    final String lowerArtist = artistName.toLowerCase();
    final bool useNumHimno = lowerArtist == 'himno' || lowerArtist == 'coritario' || lowerArtist == 'coritatio';

    if (useNumHimno) {
      sortedSongs.sort((a, b) {
        int numA = a.numHimno ?? 9999;
        int numB = b.numHimno ?? 9999;
        return numA.compareTo(numB);
      });
    } else {
      sortedSongs.sort((a, b) => a.title.compareTo(b.title));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(artistName),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: sortedSongs.length,
        itemBuilder: (context, index) {
          final song = sortedSongs[index];
          
          String titleDisplay = song.title;
          if (useNumHimno && song.numHimno != null) {
            titleDisplay = '#${song.numHimno} - $titleDisplay';
          }

          return Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
            margin: const EdgeInsets.only(bottom: 8.0),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  useNumHimno ? Icons.book : Icons.music_note,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              title: Text(
                titleDisplay,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SongScreen(song: song),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

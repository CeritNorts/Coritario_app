import 'package:flutter/material.dart';
import 'package:coritario_app/models/song.dart';
import 'package:coritario_app/screens/artist_songs_screen.dart';
import 'package:coritario_app/screens/song_screen.dart';

class ArtistsTab extends StatefulWidget {
  final List<Song> allSongs;

  const ArtistsTab({super.key, required this.allSongs});

  @override
  State<ArtistsTab> createState() => _ArtistsTabState();
}

class _ArtistsTabState extends State<ArtistsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _normalize(_searchController.text);
    });
  }

  String _normalize(String str) {
    var withDia = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÖØòóôõöøÈÉÊËèéêëÇçÌÍÎÏìíîïÙÚÛÜùúûüÿÑñ';
    var withoutDia = 'AAAAAAaaaaaaOOOOOOooooooEEEEeeeeCcIIIIiiiiUUUUuuuuyNn';
    for (int i = 0; i < withDia.length; i++) {
      str = str.replaceAll(withDia[i], withoutDia[i]);
    }
    return str.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.allSongs.isEmpty) {
      return const Center(child: Text('No hay cantos disponibles.'));
    }

    // Agrupar por artista
    Map<String, List<Song>> artistGroups = {};
    for (var song in widget.allSongs) {
      if (!artistGroups.containsKey(song.artist)) {
        artistGroups[song.artist] = [];
      }
      artistGroups[song.artist]!.add(song);
    }

    List<String> artistNames = artistGroups.keys.toList();
    artistNames.sort((a, b) {
      if (a.toLowerCase() == 'himno') return -1;
      if (b.toLowerCase() == 'himno') return 1;
      return a.compareTo(b);
    });

    List<String> filteredArtists = [];
    List<Song> filteredSongs = [];

    if (_searchQuery.isNotEmpty) {
      // Artistas que coinciden con la búsqueda
      filteredArtists = artistNames.where((artist) {
        final displayArtistName = artist.toLowerCase() == 'himno' ? 'himnario' : artist;
        return _normalize(displayArtistName).contains(_searchQuery);
      }).toList();

      // Cantos que coinciden con la búsqueda
      filteredSongs = widget.allSongs.where((song) {
        return _normalize(song.title).contains(_searchQuery);
      }).toList();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark 
        ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.2)
        : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.03);

    return Column(
      children: [
        // Barra de búsqueda estilizada
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar artista o canto...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
        ),

        Expanded(
          child: _searchQuery.isEmpty
              ? _buildAllArtistsList(artistNames, artistGroups)
              : _buildSearchResultsList(filteredArtists, filteredSongs, artistGroups, cardColor, borderColor),
        ),
      ],
    );
  }

  Widget _buildAllArtistsList(List<String> artistNames, Map<String, List<Song>> artistGroups) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      itemCount: artistNames.length,
      itemBuilder: (context, index) {
        String artist = artistNames[index];
        List<Song> artistSongs = artistGroups[artist]!;
        bool isHimnario = artist.toLowerCase() == 'himno';

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.only(bottom: 12.0),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ArtistSongsScreen(
                    artistName: artist,
                    songs: artistSongs,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isHimnario
                          ? Colors.amber.withOpacity(0.2)
                          : Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isHimnario ? Icons.menu_book : Icons.person,
                      color: isHimnario
                          ? Colors.amber.shade800
                          : Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isHimnario ? 'Himnario' : artist,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${artistSongs.length} cantos',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchResultsList(
    List<String> filteredArtists,
    List<Song> filteredSongs,
    Map<String, List<Song>> artistGroups,
    Color cardColor,
    Color borderColor,
  ) {
    if (filteredArtists.isEmpty && filteredSongs.isEmpty) {
      return const Center(
        child: Text('No se encontraron resultados.'),
      );
    }

    List<Widget> children = [];

    if (filteredArtists.isNotEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Artistas',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
      );

      children.addAll(
        filteredArtists.map((artist) {
          List<Song> artistSongs = artistGroups[artist]!;
          bool isHimnario = artist.toLowerCase() == 'himno';

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: EdgeInsets.zero,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ArtistSongsScreen(
                        artistName: artist,
                        songs: artistSongs,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isHimnario
                              ? Colors.amber.withOpacity(0.2)
                              : Theme.of(context).colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isHimnario ? Icons.menu_book : Icons.person,
                          color: isHimnario
                              ? Colors.amber.shade800
                              : Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isHimnario ? 'Himnario' : artist,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${artistSongs.length} cantos',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      );
    }

    if (filteredSongs.isNotEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Text(
            'Cantos',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
      );

      children.addAll(
        filteredSongs.map((song) {
          final isHimno = song.artist.toLowerCase() == 'himno';
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            child: Card(
              color: cardColor,
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: borderColor, width: 1),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: const Icon(Icons.music_note),
                ),
                title: Text(
                  song.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(isHimno ? 'Himnario' : song.artist),
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
            ),
          );
        }),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 16.0),
      children: children,
    );
  }
}

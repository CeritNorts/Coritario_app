import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:coritario_app/models/song.dart';
import 'package:coritario_app/screens/song_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Song> _allSongs = [];
  List<Song> _filteredSongs = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSongs();
    _searchController.addListener(_filterSongs);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSongs() async {
    try {
      // Cargamos el JSON desde los assets
      final String jsonString = await rootBundle.loadString('assets/data/canciones.json');
      final List<dynamic> jsonResponse = jsonDecode(jsonString);
      
      // Mapeamos el JSON a objetos Song
      final List<Song> loadedSongs = jsonResponse.map((data) => Song.fromJson(data)).toList();
      
      setState(() {
        _allSongs = loadedSongs;
        _filteredSongs = loadedSongs;
      });
    } catch (e) {
      debugPrint("Error loading songs: $e");
    }
  }

  void _filterSongs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredSongs = _allSongs;
      } else {
        _filteredSongs = _allSongs.where((song) {
          return song.title.toLowerCase().contains(query) || 
                 song.artist.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Coritario'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar canto o artista...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          
          // Lista de cantos
          Expanded(
            child: _allSongs.isEmpty 
              ? const Center(child: CircularProgressIndicator())
              : _filteredSongs.isEmpty 
                  ? const Center(child: Text('No se encontraron cantos.'))
                  : ListView.builder(
                      itemCount: _filteredSongs.length,
                      itemBuilder: (context, index) {
                        final song = _filteredSongs[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            child: const Icon(Icons.music_note),
                          ),
                          title: Text(
                            song.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(song.artist),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            // Navegar a la pantalla de la canción pasando el objeto Song
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SongScreen(song: song),
                              ),
                            );
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

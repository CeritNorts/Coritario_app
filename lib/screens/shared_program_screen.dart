import 'package:flutter/material.dart';
import 'package:coritario_app/models/song.dart';
import 'package:coritario_app/models/program.dart';
import 'package:coritario_app/screens/song_screen.dart';
import 'package:coritario_app/services/database_service.dart';

class SharedProgramScreen extends StatefulWidget {
  final List<String> songIds;

  const SharedProgramScreen({super.key, required this.songIds});

  @override
  State<SharedProgramScreen> createState() => _SharedProgramScreenState();
}

class _SharedProgramScreenState extends State<SharedProgramScreen> {
  List<Song> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSharedSongs();
  }

  Future<void> _loadSharedSongs() async {
    try {
      final db = DatabaseService();
      final loadedSongs = await db.getSongsByIds(widget.songIds);
      setState(() {
        _songs = loadedSongs;
      });

      if (loadedSongs.isNotEmpty) {
        final dateStr = "${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}";
        final newProgram = Program(
          name: "Programa Importado",
          date: dateStr,
          inicioSongs: widget.songIds,
          predicacionSongs: [],
          ofrendasSongs: [],
        );
        await db.insertProgram(newProgram);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Culto guardado automáticamente en tus programas"),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error loading shared songs: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Programa Compartido'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _songs.isEmpty
              ? const Center(
                  child: Text('No se encontraron canciones en este enlace compartido.'),
                )
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Has abierto un programa compartido por otro músico. Toca cualquier canto para ver sus acordes y letra.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _songs.length,
                        itemBuilder: (context, index) {
                          final song = _songs[index];
                          final isHimno = song.artist.toLowerCase() == 'himno';
                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.only(bottom: 10.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                                child: Text(
                                  isHimno && song.numHimno != null ? '#${song.numHimno}' : '🎵',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(song.artist),
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
                    ),
                  ],
                ),
    );
  }
}

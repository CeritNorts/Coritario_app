import 'package:flutter/material.dart';
import 'package:coritario_app/models/song.dart';
import 'package:coritario_app/models/program.dart';
import 'package:coritario_app/screens/song_screen.dart';
import 'package:coritario_app/services/database_service.dart';
import 'package:share_plus/share_plus.dart';

class ProgramDetailScreen extends StatefulWidget {
  final Program program;

  const ProgramDetailScreen({super.key, required this.program});

  @override
  State<ProgramDetailScreen> createState() => _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends State<ProgramDetailScreen> {
  final List<Song> _inicioSongs = [];
  final List<Song> _predicacionSongs = [];
  final List<Song> _ofrendasSongs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    try {
      final db = DatabaseService();
      final inicio = await db.getSongsByIds(widget.program.inicioSongs);
      final predicacion = await db.getSongsByIds(widget.program.predicacionSongs);
      final ofrendas = await db.getSongsByIds(widget.program.ofrendasSongs);

      setState(() {
        _inicioSongs.addAll(inicio);
        _predicacionSongs.addAll(predicacion);
        _ofrendasSongs.addAll(ofrendas);
      });
    } catch (e) {
      debugPrint("Error loading songs: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _shareProgram() {
    // Generar la lista de todos los IDs para el deep link
    final List<String> allIds = [
      ..._inicioSongs.map((s) => s.id),
      ..._predicacionSongs.map((s) => s.id),
      ..._ofrendasSongs.map((s) => s.id),
    ];

    final String deepLink = "https://ceritnorts.github.io/corario/detalle?songs=${allIds.join(',')}";

    // Construir el mensaje de WhatsApp
    final buffer = StringBuffer();
    buffer.writeln("*${widget.program.name}*");
    buffer.writeln("Fecha: ${widget.program.date}");
    buffer.writeln();

    if (_inicioSongs.isNotEmpty) {
      buffer.writeln("*Inicio:*");
      for (var s in _inicioSongs) {
        final prefix = s.numHimno != null ? "#${s.numHimno} " : "";
        buffer.writeln("  • $prefix${s.title}");
      }
      buffer.writeln();
    }

    if (_predicacionSongs.isNotEmpty) {
      buffer.writeln("*Predicación:*");
      for (var s in _predicacionSongs) {
        final prefix = s.numHimno != null ? "#${s.numHimno} " : "";
        buffer.writeln("  • $prefix${s.title}");
      }
      buffer.writeln();
    }

    if (_ofrendasSongs.isNotEmpty) {
      buffer.writeln("*Ofrendas:*");
      for (var s in _ofrendasSongs) {
        final prefix = s.numHimno != null ? "#${s.numHimno} " : "";
        buffer.writeln("  • $prefix${s.title}");
      }
      buffer.writeln();
    }

    buffer.writeln("Abrir en la aplicación Coritario:");
    buffer.writeln(deepLink);

    SharePlus.instance.share(
      ShareParams(
        text: buffer.toString(),
      ),
    );
  }

  Widget _buildSectionList(String title, List<Song> songs, Color color) {
    if (songs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            final isHimno = song.artist.toLowerCase() == 'himno';
            return Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              margin: const EdgeInsets.only(bottom: 8.0),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.1),
                  child: Text(
                    isHimno && song.numHimno != null ? '#${song.numHimno}' : '🎵',
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(song.title, style: const TextStyle(fontWeight: FontWeight.w600)),
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
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.program.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Compartir programa',
            onPressed: _isLoading ? null : _shareProgram,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      widget.program.date,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionList('Inicio', _inicioSongs, Colors.blue),
                _buildSectionList('Predicación', _predicacionSongs, Colors.red),
                _buildSectionList('Ofrendas', _ofrendasSongs, Colors.green),
                if (_inicioSongs.isEmpty && _predicacionSongs.isEmpty && _ofrendasSongs.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('Este programa está vacío.'),
                    ),
                  ),
              ],
            ),
    );
  }
}

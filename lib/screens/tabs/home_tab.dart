import 'package:flutter/material.dart';
import 'package:coritario_app/models/song.dart';
import 'package:coritario_app/models/program.dart';
import 'package:coritario_app/screens/song_screen.dart';
import 'package:coritario_app/screens/program_detail_screen.dart';
import 'package:coritario_app/screens/favorites_screen.dart';
import 'package:coritario_app/services/database_service.dart';

class HomeTab extends StatefulWidget {
  final List<Song> allSongs;
  final VoidCallback onNavigateToArtists;
  final VoidCallback onNavigateToPrograms;

  const HomeTab({
    super.key,
    required this.allSongs,
    required this.onNavigateToArtists,
    required this.onNavigateToPrograms,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  Program? _lastProgram;

  @override
  void initState() {
    super.initState();
    _loadLastProgram();
  }

  Future<void> _loadLastProgram() async {
    try {
      final programs = await DatabaseService().getPrograms();
      if (programs.isNotEmpty) {
        setState(() {
          _lastProgram = programs.first;
        });
      }
    } catch (e) {
      debugPrint("Error loading last program: $e");
    }
  }

  String _getFirstChord(String lyrics) {
    final match = RegExp(r'\[([^\]]+)\]').firstMatch(lyrics);
    return match?.group(1) ?? 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark 
        ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.2)
        : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.03);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sección de Accesos Rápidos
          Text(
            'Accesos Rápidos',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickAccessCard(
                  context,
                  title: 'Himnario',
                  icon: Icons.menu_book_rounded,
                  color: Colors.amber.shade700,
                  onTap: widget.onNavigateToArtists,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickAccessCard(
                  context,
                  title: 'Favoritos',
                  icon: Icons.favorite_rounded,
                  color: Colors.pink.shade600,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FavoritesScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickAccessCard(
                  context,
                  title: _lastProgram != null ? 'Último Culto' : 'Programas',
                  icon: _lastProgram != null ? Icons.bookmark_rounded : Icons.queue_music_rounded,
                  color: Colors.indigo.shade500,
                  onTap: () {
                    if (_lastProgram != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProgramDetailScreen(program: _lastProgram!),
                        ),
                      );
                    } else {
                      widget.onNavigateToPrograms();
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Sección de Cantos (lista corta para el Home)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Todos los Cantos',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
              ),
              TextButton.icon(
                onPressed: widget.onNavigateToArtists, // Te lleva al listado completo
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Ver Todo'),
              )
            ],
          ),
          const SizedBox(height: 8),
          
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.allSongs.length > 5 ? 5 : widget.allSongs.length,
            itemBuilder: (context, index) {
              final song = widget.allSongs[index];
              final isHimno = song.artist.toLowerCase() == 'himno';
              final String tone = _getFirstChord(song.lyrics);

              return Card(
                color: cardColor,
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 10.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: borderColor, width: 1),
                ),
                child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      child: Text(
                        isHimno && song.numHimno != null ? '#${song.numHimno}' : '🎵',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      song.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        song.artist,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (tone != 'N/A')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Tono: $tone',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
                        ),
                      ],
                    ),
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
        ],
      ),
    );
  }

  Widget _buildQuickAccessCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.08) : color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? color.withOpacity(0.25) : color.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: color.withOpacity(0.15),
          highlightColor: color.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 28, color: color),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

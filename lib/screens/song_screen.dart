import 'dart:async';
import 'package:flutter/material.dart';
import 'package:coritario_app/models/song_parser.dart';
import 'package:coritario_app/models/chord_transposer.dart';
import 'package:coritario_app/models/song.dart';
import 'package:coritario_app/services/database_service.dart';

class SongScreen extends StatefulWidget {
  final Song song; // Ahora recibe un objeto Song

  const SongScreen({super.key, required this.song});

  @override
  State<SongScreen> createState() => _SongScreenState();
}

class _SongScreenState extends State<SongScreen> {
  List<SongLine> _parsedLines = [];
  int _currentTranspose = 0; // En semitonos
  bool _isFavorite = false;

  // Lógica de Capo
  int _capoValue = 0;
  bool _noCapoMode = false;

  // Lógica de Autoscroll
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;
  bool _isAutoScrolling = false;
  double _scrollSpeed = 2.0; // Píxeles por paso (50ms)

  @override
  void initState() {
    super.initState();
    // Parseamos la letra de la canción que recibimos
    _parsedLines = SongParser.parse(widget.song.lyrics);
    _detectCapo();
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    try {
      final isFav = await DatabaseService().isFavorite(widget.song.id);
      if (mounted) {
        setState(() {
          _isFavorite = isFav;
        });
      }
    } catch (e) {
      debugPrint("Error loading favorite status: $e");
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      final newFavStatus = await DatabaseService().toggleFavorite(widget.song.id);
      if (mounted) {
        setState(() {
          _isFavorite = newFavStatus;
        });
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newFavStatus 
                  ? 'Agregado a Favoritos' 
                  : 'Eliminado de Favoritos',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error toggling favorite: $e");
    }
  }

  void _detectCapo() {
    final capoMatch = RegExp(r'capo\s*(\d+)', caseSensitive: false).firstMatch(widget.song.lyrics);
    if (capoMatch != null) {
      setState(() {
        _capoValue = int.tryParse(capoMatch.group(1) ?? '0') ?? 0;
      });
    }
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _transpose(int semitones) {
    setState(() {
      _currentTranspose += semitones;
    });
  }

  void _toggleAutoScroll() {
    setState(() {
      _isAutoScrolling = !_isAutoScrolling;
      if (_isAutoScrolling) {
        _startScroll();
      } else {
        _stopScroll();
      }
    });
  }

  void _startScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.position.pixels;

        if (currentScroll >= maxScroll) {
          _stopScroll();
          setState(() {
            _isAutoScrolling = false;
          });
          return;
        }

        _scrollController.animateTo(
          currentScroll + _scrollSpeed,
          duration: const Duration(milliseconds: 50),
          curve: Curves.linear,
        );
      }
    });
  }

  void _stopScroll() {
    _scrollTimer?.cancel();
  }

  void _adjustSpeed(double delta) {
    setState(() {
      _scrollSpeed = (_scrollSpeed + delta).clamp(0.5, 10.0);
      // Si ya está haciendo scroll, reiniciamos el timer para aplicar la velocidad
      if (_isAutoScrolling) {
        _startScroll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isWideScreen = MediaQuery.of(context).size.width > 600;
    final int effectiveTranspose = _currentTranspose + (_noCapoMode ? _capoValue : 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.song.title),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : null,
            ),
            onPressed: _toggleFavorite,
            tooltip: _isFavorite ? 'Quitar de favoritos' : 'Agregar a favoritos',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Cabecera superior con opción "Tocar sin Capo" si se detecta capo
            if (_capoValue > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Detectado: Capo $_capoValue",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    FilterChip(
                      label: const Text("Tocar sin Capo"),
                      selected: _noCapoMode,
                      onSelected: (val) {
                        setState(() {
                          _noCapoMode = val;
                        });
                      },
                      selectedColor: Theme.of(context).colorScheme.primaryContainer,
                      checkmarkColor: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),

            // Barra de controles de autoscroll integrada en el menú superior
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: _toggleAutoScroll,
                    icon: Icon(_isAutoScrolling ? Icons.pause : Icons.play_arrow),
                    style: IconButton.styleFrom(
                      backgroundColor: _isAutoScrolling 
                          ? Colors.red.withOpacity(0.2) 
                          : Theme.of(context).colorScheme.primaryContainer,
                      foregroundColor: _isAutoScrolling 
                          ? Colors.red 
                          : Theme.of(context).colorScheme.primary,
                    ),
                    tooltip: _isAutoScrolling ? 'Pausar autoscroll' : 'Iniciar autoscroll',
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Autoscroll",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.remove, size: 20),
                    onPressed: () => _adjustSpeed(-0.5),
                    tooltip: 'Bajar velocidad',
                  ),
                  Text(
                    'Vel: ${_scrollSpeed.toStringAsFixed(1)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    onPressed: () => _adjustSpeed(0.5),
                    tooltip: 'Subir velocidad',
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(
                  vertical: 20.0,
                  horizontal: isWideScreen ? 60.0 : 20.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.song.title,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.song.artist,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                    const SizedBox(height: 32),
                    
                    _buildChordViewer(isWideScreen, effectiveTranspose),
                  ],
                ),
              ),
            ),
            
            // Barra inferior con controles de transposición
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTransposeButton('-1', () => _transpose(-2), 'Tono'),
                    _buildTransposeButton('-½', () => _transpose(-1), 'Tono'),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        _currentTranspose > 0 
                            ? '+$_currentTranspose' 
                            : '$_currentTranspose',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    
                    _buildTransposeButton('+½', () => _transpose(1), 'Tono'),
                    _buildTransposeButton('+1', () => _transpose(2), 'Tono'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChordViewer(bool isWideScreen, int effectiveTranspose) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _parsedLines.map((line) {
        if (line.isEmpty) {
          return const SizedBox(height: 20);
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            children: line.segments.map((segment) {
              String? transposedChord;
              if (segment.chord != null) {
                transposedChord = ChordTransposer.transposeChord(segment.chord!, effectiveTranspose);
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (transposedChord != null)
                    Text(
                      transposedChord,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isWideScreen ? 18 : 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  Text(
                    segment.text,
                    style: TextStyle(
                      fontSize: isWideScreen ? 20 : 18,
                      height: 1.2,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTransposeButton(String label, VoidCallback onPressed, String subtitle) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
            elevation: 2,
          ),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        )
      ],
    );
  }
}

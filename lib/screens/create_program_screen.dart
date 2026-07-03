import 'package:flutter/material.dart';
import 'package:coritario_app/models/song.dart';
import 'package:coritario_app/models/program.dart';
import 'package:coritario_app/services/database_service.dart';

class CreateProgramScreen extends StatefulWidget {
  final Program? program;

  const CreateProgramScreen({super.key, this.program});

  @override
  State<CreateProgramScreen> createState() => _CreateProgramScreenState();
}

class _CreateProgramScreenState extends State<CreateProgramScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _dateController;

  List<Song> _allSongs = [];
  final List<Song> _inicioSongs = [];
  final List<Song> _predicacionSongs = [];
  final List<Song> _ofrendasSongs = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.program?.name ?? '');
    _dateController = TextEditingController(text: widget.program?.date ?? _formatCurrentDate());
    _loadData();
  }

  String _formatCurrentDate() {
    final now = DateTime.now();
    return "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
  }

  Future<void> _loadData() async {
    try {
      _allSongs = await DatabaseService().getSongs();
      
      if (widget.program != null) {
        final db = DatabaseService();
        final inicio = await db.getSongsByIds(widget.program!.inicioSongs);
        final predicacion = await db.getSongsByIds(widget.program!.predicacionSongs);
        final ofrendas = await db.getSongsByIds(widget.program!.ofrendasSongs);

        setState(() {
          _inicioSongs.addAll(inicio);
          _predicacionSongs.addAll(predicacion);
          _ofrendasSongs.addAll(ofrendas);
        });
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _addSongToSection(List<Song> sectionList) {
    showDialog(
      context: context,
      builder: (context) => _SongSearchDialog(
        allSongs: _allSongs,
        onSongSelected: (song) {
          setState(() {
            if (!sectionList.any((s) => s.id == song.id)) {
              sectionList.add(song);
            }
          });
        },
      ),
    );
  }

  void _removeSongFromSection(List<Song> sectionList, int index) {
    setState(() {
      sectionList.removeAt(index);
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  Future<void> _saveProgram() async {
    if (!_formKey.currentState!.validate()) return;

    final program = Program(
      id: widget.program?.id,
      name: _nameController.text.trim(),
      date: _dateController.text.trim(),
      inicioSongs: _inicioSongs.map((s) => s.id).toList(),
      predicacionSongs: _predicacionSongs.map((s) => s.id).toList(),
      ofrendasSongs: _ofrendasSongs.map((s) => s.id).toList(),
    );

    final db = DatabaseService();
    if (widget.program == null) {
      await db.insertProgram(program);
    } else {
      await db.updateProgram(program);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Widget _buildSectionCard(String title, List<Song> sectionList, Color color) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 24,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton.filledTonal(
                  onPressed: () => _addSongToSection(sectionList),
                  icon: const Icon(Icons.add, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: color.withOpacity(0.15),
                    foregroundColor: color,
                  ),
                ),
              ],
            ),
            const Divider(),
            if (sectionList.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Text(
                    'No hay cantos en esta sección',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sectionList.length,
                itemBuilder: (context, index) {
                  final song = sectionList[index];
                  final isHimno = song.artist.toLowerCase() == 'himno';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.1),
                      child: Text(
                        isHimno && song.numHimno != null ? '#${song.numHimno}' : '🎵',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      song.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(song.artist),
                    trailing: IconButton(
                      onPressed: () => _removeSongFromSection(sectionList, index),
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.program == null ? 'Crear Programa' : 'Editar Programa'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _saveProgram,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Nombre del programa
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Programa',
                hintText: 'Ej. Culto de Domingo por la Mañana',
                border: OutlineInputBorder(),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            
            // Fecha
            TextFormField(
              controller: _dateController,
              decoration: InputDecoration(
                labelText: 'Fecha',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.calendar_today),
                ),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 24),

            // Secciones
            _buildSectionCard('Inicio', _inicioSongs, Colors.blue),
            _buildSectionCard('Predicación', _predicacionSongs, Colors.red),
            _buildSectionCard('Ofrendas', _ofrendasSongs, Colors.green),
          ],
        ),
      ),
    );
  }
}

class _SongSearchDialog extends StatefulWidget {
  final List<Song> allSongs;
  final ValueChanged<Song> onSongSelected;

  const _SongSearchDialog({required this.allSongs, required this.onSongSelected});

  @override
  State<_SongSearchDialog> createState() => _SongSearchDialogState();
}

class _SongSearchDialogState extends State<_SongSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Song> _filteredSongs = [];

  @override
  void initState() {
    super.initState();
    _filteredSongs = widget.allSongs;
    _searchController.addListener(_filterSongs);
  }

  void _filterSongs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSongs = widget.allSongs.where((song) {
        return song.title.toLowerCase().contains(query) ||
            song.artist.toLowerCase().contains(query) ||
            (song.numHimno?.toString().contains(query) ?? false);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seleccionar Canto'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredSongs.length,
                itemBuilder: (context, index) {
                  final song = _filteredSongs[index];
                  final isHimno = song.artist.toLowerCase() == 'himno';
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        isHimno && song.numHimno != null ? '#${song.numHimno}' : '🎵',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(song.title),
                    subtitle: Text(song.artist),
                    onTap: () {
                      widget.onSongSelected(song);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

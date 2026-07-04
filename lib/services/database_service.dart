import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coritario_app/models/song.dart';
import 'package:coritario_app/models/program.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  // Estructuras en memoria para simulación Web en desarrollo/testing
  static final Set<String> _webFavorites = {};
  static final List<Program> _webPrograms = [];

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError("El acceso a la base de datos SQLite no está soportado en la Web.");
    }
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Solo inicializar FFI si es escritorio nativo y no estamos en la Web
    if (!kIsWeb && (Platform.isLinux || Platform.isWindows)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'coritario.db');

    return await openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE songs (
            id TEXT PRIMARY KEY,
            title TEXT,
            artist TEXT,
            num_himno INTEGER,
            lyrics TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE programs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            date TEXT,
            inicio_songs TEXT,
            predicacion_songs TEXT,
            ofrendas_songs TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE favorites (
            song_id TEXT PRIMARY KEY
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute('DROP TABLE IF EXISTS songs');
          await db.execute('''
            CREATE TABLE songs (
              id TEXT PRIMARY KEY,
              title TEXT,
              artist TEXT,
              num_himno INTEGER,
              lyrics TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS programs (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT,
              date TEXT,
              inicio_songs TEXT,
              predicacion_songs TEXT,
              ofrendas_songs TEXT
            )
          ''');
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS favorites (
              song_id TEXT PRIMARY KEY
            )
          ''');
        }
      },
    );
  }

  Future<List<Song>> getSongs() async {
    if (kIsWeb) {
      // Intentar cargar desde Firestore primero
      try {
        final snapshot = await FirebaseFirestore.instance.collection('canciones').get();
        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return Song(
              id: doc.id,
              title: data['title'] as String? ?? '',
              artist: data['artist'] as String? ?? '',
              numHimno: data['num_himno'] as int?,
              lyrics: data['lyrics'] as String? ?? '',
            );
          }).toList();
        }
      } catch (e) {
        debugPrint("Firestore no disponible o sin inicializar. Cargando del JSON local: $e");
      }

      // Fallback a JSON local si falla Firestore
      try {
        final String jsonString = await rootBundle.loadString('assets/data/canciones.json');
        final List<dynamic> jsonResponse = jsonDecode(jsonString);
        return jsonResponse.map((data) => Song.fromJson(data)).toList();
      } catch (e) {
        debugPrint("Error al cargar JSON local: $e");
        return [];
      }
    }

    final db = await database;
    
    // Inicializamos y sincronizamos los datos si es necesario
    await _syncDataIfNeeded(db);

    final List<Map<String, dynamic>> maps = await db.query('songs');

    return List.generate(maps.length, (i) {
      return Song(
        id: maps[i]['id'] as String,
        title: maps[i]['title'] as String,
        artist: maps[i]['artist'] as String,
        numHimno: maps[i]['num_himno'] as int?,
        lyrics: maps[i]['lyrics'] as String,
      );
    });
  }

  Future<List<Song>> getSongsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    if (kIsWeb) {
      // Cargar desde Firestore o fallback
      try {
        final List<Song> results = [];
        for (var id in ids) {
          final doc = await FirebaseFirestore.instance.collection('canciones').doc(id).get();
          if (doc.exists) {
            final data = doc.data()!;
            results.add(Song(
              id: doc.id,
              title: data['title'] as String? ?? '',
              artist: data['artist'] as String? ?? '',
              numHimno: data['num_himno'] as int?,
              lyrics: data['lyrics'] as String? ?? '',
            ));
          }
        }
        if (results.isNotEmpty) return results;
      } catch (e) {
        debugPrint("Error al consultar IDs en Firestore, usando fallback local: $e");
      }

      final allSongs = await getSongs();
      final Map<String, Song> songMap = {for (var s in allSongs) s.id: s};
      return ids.map((id) => songMap[id]).whereType<Song>().toList();
    }

    final db = await database;
    // Creamos placeholders (?, ?, ...) para la consulta IN
    final placeholders = List.filled(ids.length, '?').join(',');
    final List<Map<String, dynamic>> maps = await db.query(
      'songs',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );

    final List<Song> list = List.generate(maps.length, (i) {
      return Song(
        id: maps[i]['id'] as String,
        title: maps[i]['title'] as String,
        artist: maps[i]['artist'] as String,
        numHimno: maps[i]['num_himno'] as int?,
        lyrics: maps[i]['lyrics'] as String,
      );
    });

    // Mantener el orden original de los IDs solicitados
    final Map<String, Song> songMap = {for (var s in list) s.id: s};
    return ids.map((id) => songMap[id]).whereType<Song>().toList();
  }

  // --- Operaciones de Programas ---

  Future<List<Program>> getPrograms() async {
    if (kIsWeb) {
      return _webPrograms;
    }

    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('programs', orderBy: 'id DESC');
    return List.generate(maps.length, (i) => Program.fromMap(maps[i]));
  }

  Future<int> insertProgram(Program program) async {
    if (kIsWeb) {
      final newId = _webPrograms.length + 1;
      final newProgram = Program(
        id: newId,
        name: program.name,
        date: program.date,
        inicioSongs: program.inicioSongs,
        predicacionSongs: program.predicacionSongs,
        ofrendasSongs: program.ofrendasSongs,
      );
      _webPrograms.insert(0, newProgram);
      return newId;
    }

    final db = await database;
    return await db.insert('programs', program.toMap());
  }

  Future<int> updateProgram(Program program) async {
    if (kIsWeb) {
      final idx = _webPrograms.indexWhere((p) => p.id == program.id);
      if (idx != -1) {
        _webPrograms[idx] = program;
        return 1;
      }
      return 0;
    }

    final db = await database;
    return await db.update(
      'programs',
      program.toMap(),
      where: 'id = ?',
      whereArgs: [program.id],
    );
  }

  Future<int> deleteProgram(int id) async {
    if (kIsWeb) {
      _webPrograms.removeWhere((p) => p.id == id);
      return 1;
    }

    final db = await database;
    return await db.delete(
      'programs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> _syncDataIfNeeded(Database db) async {
    // 1. Obtener cantidad de canciones en la base de datos local
    final List<Map<String, dynamic>> countResult = await db.rawQuery('SELECT COUNT(*) as count FROM songs');
    final int dbCount = countResult.first['count'] as int? ?? 0;

    // 2. Si está vacía o necesitamos sincronizar, cargamos el JSON
    if (dbCount == 0) {
      await _importFromJson(db);
    } else {
      // Lógica de sincronización: leer el archivo JSON para comparar la cantidad
      try {
        final String jsonString = await rootBundle.loadString('assets/data/canciones.json');
        final List<dynamic> jsonResponse = jsonDecode(jsonString);
        
        if (jsonResponse.length > dbCount) {
          // Hay canciones nuevas en el JSON, sincronizamos insertando o reemplazando todo
          await _importSongsList(db, jsonResponse);
        }
      } catch (e) {
        // En caso de error, omitimos para no interferir con la carga normal
        debugPrint("Error al sincronizar canciones: $e");
      }
    }
  }

  Future<void> _importFromJson(Database db) async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/canciones.json');
      final List<dynamic> jsonResponse = jsonDecode(jsonString);
      await _importSongsList(db, jsonResponse);
    } catch (e) {
      debugPrint("Error al importar canciones del JSON: $e");
    }
  }

  Future<void> _importSongsList(Database db, List<dynamic> songsJsonList) async {
    final batch = db.batch();
    for (var songJson in songsJsonList) {
      final String rawId = songJson['id'] as String;
      final String artist = songJson['artist'] as String;
      final String uniqueId = "${artist.toLowerCase()}_$rawId";

      batch.insert(
        'songs',
        {
          'id': uniqueId,
          'title': songJson['title'] as String,
          'artist': artist,
          'num_himno': songJson['num_himno'] as int?,
          'lyrics': songJson['lyrics'] as String,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  // --- Operaciones de Favoritos ---

  Future<bool> isFavorite(String songId) async {
    if (kIsWeb) {
      return _webFavorites.contains(songId);
    }

    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'favorites',
      where: 'song_id = ?',
      whereArgs: [songId],
    );
    return maps.isNotEmpty;
  }

  Future<bool> toggleFavorite(String songId) async {
    if (kIsWeb) {
      if (_webFavorites.contains(songId)) {
        _webFavorites.remove(songId);
        return false; // Ya no es favorito
      } else {
        _webFavorites.add(songId);
        return true; // Ahora es favorito
      }
    }

    final db = await database;
    final List<Map<String, dynamic>> exists = await db.query(
      'favorites',
      where: 'song_id = ?',
      whereArgs: [songId],
    );
    if (exists.isNotEmpty) {
      await db.delete(
        'favorites',
        where: 'song_id = ?',
        whereArgs: [songId],
      );
      return false; // Ya no es favorito
    } else {
      await db.insert(
        'favorites',
        {'song_id': songId},
      );
      return true; // Ahora es favorito
    }
  }

  Future<List<Song>> getFavoriteSongs() async {
    if (kIsWeb) {
      final allSongs = await getSongs();
      return allSongs.where((s) => _webFavorites.contains(s.id)).toList();
    }

    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT s.* FROM songs s
      INNER JOIN favorites f ON s.id = f.song_id
      ORDER BY s.title ASC
    ''');

    return List.generate(maps.length, (i) {
      return Song(
        id: maps[i]['id'] as String,
        title: maps[i]['title'] as String,
        artist: maps[i]['artist'] as String,
        numHimno: maps[i]['num_himno'] as int?,
        lyrics: maps[i]['lyrics'] as String,
      );
    });
  }
}

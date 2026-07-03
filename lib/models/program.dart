class Program {
  final int? id;
  final String name;
  final String date;
  final List<String> inicioSongs;
  final List<String> predicacionSongs;
  final List<String> ofrendasSongs;

  Program({
    this.id,
    required this.name,
    required this.date,
    required this.inicioSongs,
    required this.predicacionSongs,
    required this.ofrendasSongs,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'date': date,
      'inicio_songs': inicioSongs.join(','),
      'predicacion_songs': predicacionSongs.join(','),
      'ofrendas_songs': ofrendasSongs.join(','),
    };
  }

  factory Program.fromMap(Map<String, dynamic> map) {
    return Program(
      id: map['id'] as int?,
      name: map['name'] as String,
      date: map['date'] as String,
      inicioSongs: (map['inicio_songs'] as String).isEmpty
          ? []
          : (map['inicio_songs'] as String).split(','),
      predicacionSongs: (map['predicacion_songs'] as String).isEmpty
          ? []
          : (map['predicacion_songs'] as String).split(','),
      ofrendasSongs: (map['ofrendas_songs'] as String).isEmpty
          ? []
          : (map['ofrendas_songs'] as String).split(','),
    );
  }
}

class Song {
  final String id;
  final String title;
  final String artist;
  final int? numHimno;
  final String lyrics;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    this.numHimno,
    required this.lyrics,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      numHimno: json['num_himno'] as int?,
      lyrics: json['lyrics'] as String,
    );
  }
}

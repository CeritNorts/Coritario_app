class ChordTransposer {
  // Arreglos con la escala cromática de 12 notas.
  // Uno para sostenidos (#) y otro para bemoles (b).
  static const List<String> _sharps = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
  static const List<String> _flats  = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'];

  /// Convierte cualquier nota a su índice correspondiente (0 al 11).
  static int _getNoteIndex(String note) {
    int index = _sharps.indexOf(note);
    if (index == -1) {
      index = _flats.indexOf(note);
    }
    return index;
  }

  /// Recibe un acorde (ej. "C#m7" o "G/B") y le suma/resta la cantidad de semitonos indicada.
  static String transposeChord(String chord, int semitones) {
    // Si no hay transposición o el acorde está vacío, devolvemos el original
    if (semitones == 0 || chord.isEmpty) return chord;

    // Manejo especial para acordes con bajos invertidos (ej. "G/B")
    if (chord.contains('/')) {
      List<String> parts = chord.split('/');
      if (parts.length == 2) {
        String newRoot = _transposePart(parts[0], semitones);
        String newBass = _transposePart(parts[1], semitones);
        return '$newRoot/$newBass';
      }
    }

    // Transposición de un acorde normal
    return _transposePart(chord, semitones);
  }

  /// Transpone una parte individual del acorde sin el bajo (ej. "C#m7" -> transpone "C#" y conserva "m7")
  static String _transposePart(String part, int semitones) {
    // Expresión regular: 
    // Grupo 1: Captura la nota base de A a G, seguida opcionalmente de # o b.
    // Grupo 2: Captura el resto del texto (modificadores como m, 7, maj7, aug, dim, etc.)
    RegExp regex = RegExp(r'^([CDEFGAB][#b]?)(.*)$');
    Match? match = regex.firstMatch(part);

    // Si el texto no parece un acorde válido (ej. si pusieron un comentario en vez de un acorde),
    // lo devolvemos intacto para no romper la app.
    if (match == null) {
      return part;
    }

    String rootNote = match.group(1)!;
    String modifier = match.group(2)!;

    int rootIndex = _getNoteIndex(rootNote);
    
    // Si por alguna razón la nota no existe en nuestra escala, devolvemos intacto
    if (rootIndex == -1) return part;

    // --- LA MAGIA MATEMÁTICA ---
    // Sumamos los semitonos al índice original.
    // Usamos (valor % 12 + 12) % 12 para garantizar que el resultado sea siempre un número positivo
    // entre 0 y 11, sin importar si los semitonos son negativos (bajando de tono).
    int newIndex = ((rootIndex + semitones) % 12 + 12) % 12;

    // Nota de diseño: Por simplicidad, en esta versión base devolveremos todos los acordes transuestos
    // usando la escala de sostenidos. Más adelante podemos agregar lógica para preferir bemoles 
    // dependiendo de la tonalidad de la canción.
    String newRoot = _sharps[newIndex];

    return '$newRoot$modifier';
  }
}

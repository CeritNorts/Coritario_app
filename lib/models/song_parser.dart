class ChordLyricSegment {
  final String? chord;
  final String text;

  ChordLyricSegment({this.chord, required this.text});

  @override
  String toString() {
    if (chord != null) {
      return '[$chord]$text';
    }
    return text;
  }
}

class SongLine {
  final List<ChordLyricSegment> segments;

  SongLine(this.segments);

  // Un método útil para saber si la línea está completamente vacía (útil para los saltos de párrafo)
  bool get isEmpty => segments.isEmpty || (segments.length == 1 && segments.first.chord == null && segments.first.text.trim().isEmpty);
}

class SongParser {
  /// Recibe un string con el contenido en formato ChordPro y devuelve una lista de líneas procesadas.
  static List<SongLine> parse(String chordProText) {
    List<SongLine> parsedLines = [];
    // Separamos el texto completo por saltos de línea (maneja tanto \r\n como \n)
    List<String> rawLines = chordProText.split(RegExp(r'\r?\n'));

    for (var rawLine in rawLines) {
      parsedLines.add(_parseLine(rawLine));
    }
    
    return parsedLines;
  }

  static SongLine _parseLine(String line) {
    List<ChordLyricSegment> segments = [];
    
    // Si la línea no tiene corchetes (no tiene acordes), toda la línea es solo texto
    if (!line.contains('[')) {
      segments.add(ChordLyricSegment(chord: null, text: line));
      return SongLine(segments);
    }

    int currentIndex = 0;

    while (currentIndex < line.length) {
      int openBracketIndex = line.indexOf('[', currentIndex);
      
      // Si ya no hay más corchetes de apertura, el resto es texto sin acorde
      if (openBracketIndex == -1) {
        segments.add(ChordLyricSegment(
          chord: null, 
          text: line.substring(currentIndex)
        ));
        break;
      }

      // Si hay texto antes del primer acorde, lo agregamos como un segmento sin acorde
      if (openBracketIndex > currentIndex) {
        segments.add(ChordLyricSegment(
          chord: null,
          text: line.substring(currentIndex, openBracketIndex)
        ));
      }

      int closeBracketIndex = line.indexOf(']', openBracketIndex);
      
      // Si falta el corchete de cierre (formato inválido), tratamos el resto como texto
      if (closeBracketIndex == -1) {
        segments.add(ChordLyricSegment(
          chord: null,
          text: line.substring(openBracketIndex)
        ));
        break;
      }

      // Extraemos el acorde (lo que está adentro de los corchetes)
      String chord = line.substring(openBracketIndex + 1, closeBracketIndex);
      
      // Ahora buscamos dónde empieza el próximo acorde para saber hasta dónde llega la letra de este segmento
      int nextOpenBracketIndex = line.indexOf('[', closeBracketIndex);
      String text;
      
      if (nextOpenBracketIndex == -1) {
        // No hay más acordes en la línea, tomamos el resto de la línea
        text = line.substring(closeBracketIndex + 1);
        currentIndex = line.length; // Terminamos el ciclo
      } else {
        // Hay otro acorde, tomamos el texto hasta ese próximo acorde
        text = line.substring(closeBracketIndex + 1, nextOpenBracketIndex);
        currentIndex = nextOpenBracketIndex; // Avanzamos el índice para la siguiente iteración
      }

      segments.add(ChordLyricSegment(chord: chord, text: text));
    }

    return SongLine(segments);
  }
}

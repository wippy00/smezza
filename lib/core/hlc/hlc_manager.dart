class Hlc implements Comparable<Hlc> {
  final int timestampMs;
  final int counter;
  final String
  nodeId; // Nel nostro caso è l'UUID dell'utente (la chiave pubblica)

  // 1. Costruttore compatto con parametri nominati
  const Hlc({
    required this.timestampMs,
    required this.counter,
    required this.nodeId,
  });

  // 2. Factory Constructor per creare un HLC adesso
  factory Hlc.now(String nodeId, {Hlc? lastKnown}) {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Se non abbiamo un HLC precedente o l'orologio di sistema è andato avanti
    if (lastKnown == null || now > lastKnown.timestampMs) {
      return Hlc(timestampMs: now, counter: 0, nodeId: nodeId);
    }

    // Se l'orologio di sistema è andato indietro o è fermo,
    // teniamo l'ultimo timestamp noto e incrementiamo il contatore logico.
    return Hlc(
      timestampMs: lastKnown.timestampMs,
      counter: lastKnown.counter + 1,
      nodeId: nodeId,
    );
  }

  // 3. Factory Constructor per ricostruire l'HLC da una stringa salvata nel DB
  factory Hlc.fromString(String s) {
    final parts = s.split(':');
    if (parts.length < 3) {
      throw FormatException('Formato HLC non valido: $s');
    }
    return Hlc(
      timestampMs: int.parse(parts[0]),
      counter: int.parse(parts[1]),
      // Nel caso in cui il nodeId contenga dei caratteri ':' (anche se in Base64URL è raro)
      nodeId: parts.sublist(2).join(':'),
    );
  }

  // 4. Formattazione a stringa con padding fisso (es. "000001738933500:0002:user_id")
  @override
  String toString() {
    final tsPad = timestampMs.toString().padLeft(15, '0');
    final cntPad = counter.toString().padLeft(4, '0');
    return '$tsPad:$cntPad:$nodeId';
  }

  // 5. Comparazione e Operatori
  @override
  int compareTo(Hlc other) {
    // Essendo formattato con padding fisso, il confronto tra stringhe è identico al confronto numerico
    return toString().compareTo(other.toString());
  }

  bool operator >(Hlc other) => compareTo(other) > 0;
  bool operator <(Hlc other) => compareTo(other) < 0;
  bool operator >=(Hlc other) => compareTo(other) >= 0;
  bool operator <=(Hlc other) => compareTo(other) <= 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Hlc &&
          runtimeType == other.runtimeType &&
          toString() == other.toString();

  @override
  int get hashCode => toString().hashCode;
}

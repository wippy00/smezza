import 'package:flutter_test/flutter_test.dart';
import 'package:smezza/core/hlc/hlc_manager.dart'; // Cambia con il tuo path reale

void main() {
  group('Hlc Tests', () {
    const nodeId = 'utente_test_123';

    test('Dovrebbe formattare correttamente in stringa con padding', () {
      final hlc = Hlc(timestampMs: 12345, counter: 3, nodeId: nodeId);

      // 12345 con padLeft a 15 -> "000000000012345"
      // 3 con padLeft a 4 -> "0003"
      expect(hlc.toString(), equals('000000000012345:0003:utente_test_123'));
    });

    test('Dovrebbe ricostruire l HLC da stringa correttamente', () {
      const stringa = '000001738933500:0002:utente_test_123';
      final hlc = Hlc.fromString(stringa);

      expect(hlc.timestampMs, equals(1738933500));
      expect(hlc.counter, equals(2));
      expect(hlc.nodeId, equals('utente_test_123'));
      expect(hlc.toString(), equals(stringa));
    });

    test(
      'Dovrebbe incrementare il contatore logico se il tempo di sistema non è avanzato',
      () {
        // Creiamo un HLC fittizio che sembra essere nel futuro rispetto al tempo di sistema
        final futuro = DateTime.now().millisecondsSinceEpoch + 100000;
        final hlcPrecedente = Hlc(
          timestampMs: futuro,
          counter: 0,
          nodeId: nodeId,
        );

        // Chiediamo un nuovo HLC. Poiché l'orologio di sistema è "indietro" rispetto a hlcPrecedente,
        // l'HLC deve mantenere il timestamp futuro ma incrementare il counter a 1.
        final nuovoHlc = Hlc.now(nodeId, lastKnown: hlcPrecedente);

        expect(nuovoHlc.timestampMs, equals(hlcPrecedente.timestampMs));
        expect(nuovoHlc.counter, equals(1));
      },
    );

    test('Dovrebbe supportare i confronti matematici correttamente', () {
      final hlcBasso = Hlc(timestampMs: 100, counter: 1, nodeId: nodeId);
      final hlcMedio = Hlc(timestampMs: 100, counter: 2, nodeId: nodeId);
      final hlcAlto = Hlc(timestampMs: 200, counter: 0, nodeId: nodeId);

      expect(hlcMedio > hlcBasso, isTrue);
      expect(hlcAlto > hlcMedio, isTrue);
      expect(hlcBasso < hlcAlto, isTrue);
      expect(
        hlcBasso == Hlc(timestampMs: 100, counter: 1, nodeId: nodeId),
        isTrue,
      );
    });
  });
}

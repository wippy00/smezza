import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:smezza/core/identity/identity_manager.dart'; // Cambia con il tuo path reale

void main() {
  // Configura i mock di Flutter prima di eseguire i test
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IdentityService Tests', () {
    // resetta lo storage prima di ogni singolo test
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
    });

    test('Dovrebbe generare una nuova chiave se lo storage è vuoto', () async {
      final service = IdentityService();

      await service.init();

      // Verifica che l'UUID (chiave pubblica) sia stato generato ed è valido (lungo circa 43-44 char)
      expect(service.uuid, isNotEmpty);
      expect(service.uuid.length, greaterThan(40));
    });

    test('Dovrebbe caricare la stessa chiave nei riavvii successivi', () async {
      final service1 = IdentityService();
      await service1.init();
      final uuidGenerato = service1.uuid;

      // Simuliamo il riavvio dell'app creando una nuova istanza dello storage
      // che però leggerà gli stessi valori precedentemente salvati nel mock
      final service2 = IdentityService();
      await service2.init();

      expect(service2.uuid, equals(uuidGenerato));
    });

    test('Dovrebbe firmare e verificare correttamente un messaggio', () async {
      final service = IdentityService();
      await service.init();

      const messaggio = "Spesa di 15.50 EUR per la cena";
      final firma = await service.sign(messaggio);

      // 1. Verifica positiva con la nostra chiave pubblica
      final valid = await service.verify(
        message: messaggio,
        signatureBase64: firma,
        publicKeyBase64: service.uuid,
      );
      expect(valid, isTrue);

      // 2. Verifica negativa se il messaggio è alterato (manomissione)
      final invalid = await service.verify(
        message: "Spesa di 99.99 EUR per la cena", // Messaggio modificato
        signatureBase64: firma,
        publicKeyBase64: service.uuid,
      );
      expect(invalid, isFalse);
    });
  });
}

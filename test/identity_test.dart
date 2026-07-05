import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smezza/core/identity/identity_manager.dart'; // Cambia con il tuo path reale

void main() {
  // Configura i mock di Flutter prima di eseguire i test
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IdentityService Tests', () {
    // resetta lo storage prima di ogni singolo test
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
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

    test('nextHlc dovrebbe restituire HLC monotonicamente crescenti', () async {
      final service = IdentityService();
      await service.init();

      final hlc1 = service.nextHlc();
      final hlc2 = service.nextHlc();
      final hlc3 = service.nextHlc();

      expect(hlc2 > hlc1, isTrue);
      expect(hlc3 > hlc2, isTrue);
      expect(hlc1.nodeId, equals(service.uuid));
    });

    test(
      'exportKey dovrebbe restituire lo stesso seed usato da importKey su un\'altra istanza',
      () async {
        final service1 = IdentityService();
        await service1.init();
        final seedEsportato = service1.exportKey();
        final uuidOriginale = service1.uuid;

        // Simuliamo un nuovo dispositivo/istanza pulita che importa la chiave
        FlutterSecureStorage.setMockInitialValues({});
        final service2 = IdentityService();
        await service2.importKey(seedEsportato);

        expect(service2.uuid, equals(uuidOriginale));
      },
    );

    test(
      'exportKeyAsync dovrebbe leggere il seed direttamente dallo storage',
      () async {
        final service = IdentityService();
        await service.init();

        final seedSync = service.exportKey();
        final seedAsync = await service.exportKeyAsync();

        expect(seedAsync, equals(seedSync));
      },
    );

    test(
      'forceNewIdentity dovrebbe generare una chiave diversa dalla precedente',
      () async {
        final service = IdentityService();
        await service.init();
        final vecchioUuid = service.uuid;

        await service.forceNewIdentity();

        expect(service.uuid, isNot(equals(vecchioUuid)));
      },
    );

    test(
      'wipeIdentity dovrebbe azzerare lo stato e richiedere una nuova init',
      () async {
        final service = IdentityService();
        await service.init();

        await service.wipeIdentity();

        // Dopo il wipe, uuid non è più disponibile finché non si richiama init()
        expect(() => service.uuid, throwsException);
      },
    );

    test(
      'isBackupConfirmed dovrebbe essere false di default e true dopo confirmBackup',
      () async {
        final service = IdentityService();
        await service.init();

        expect(await service.isBackupConfirmed(), isFalse);

        await service.confirmBackup();
        expect(await service.isBackupConfirmed(), isTrue);

        await service.resetBackupFlag();
        expect(await service.isBackupConfirmed(), isFalse);
      },
    );

    test(
      'init dovrebbe rigenerare una chiave pulita se lo storage contiene una chiave corrotta',
      () async {
        // Chiave con lunghezza in byte errata (non 32 byte) dopo la decodifica base64Url
        FlutterSecureStorage.setMockInitialValues({
          'user_private_key': 'YQ', // decodifica a 1 solo byte
        });

        final service = IdentityService();
        await service.init();

        // Nonostante lo storage corrotto, il servizio deve auto-ripararsi
        // generando una nuova chiave valida invece di lanciare un'eccezione.
        expect(service.uuid, isNotEmpty);
        expect(service.uuid.length, greaterThan(40));
      },
    );

    test(
      'importKey dovrebbe rifiutare un seed di lunghezza non valida',
      () async {
        final service = IdentityService();

        expect(
          () => service.importKey('dGVzdA'), // "test" -> solo 4 byte
          throwsException,
        );
      },
    );

    test(
      'uuid dovrebbe lanciare eccezione se il servizio non è stato inizializzato',
      () {
        final service = IdentityService();
        expect(() => service.uuid, throwsException);
      },
    );
  });
}

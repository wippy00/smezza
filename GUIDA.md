# Smezza – Guida al Progetto (v4)

> **Filosofia:** Il database locale è la fonte della verità — l'app funziona sempre, anche offline. PocketBase è il layer di sincronizzazione, non il cervello dell'app.
>
> **Obiettivo immediato:** un MVP con login, gruppi, spese e sync in tempo reale. Tutto scritto in modo che aggiungere Nearby Connections o qualsiasi altra feature futura non richieda di riscrivere nulla.

---

## Concetti Chiave (leggi prima di tutto il resto)

Prima di entrare nel codice, questi sono i concetti architetturali che guidano ogni scelta. Vale la pena capirli bene perché spiegano il *perché* di molte decisioni che altrimenti sembrerebbero inutilmente complesse.

### Interfacce e Dependency Injection — il principio base

Un'**interfaccia** (in Dart: `abstract class`) è un contratto: definisce *cosa* fa un componente, senza dire *come* lo fa. Chi usa il componente conosce solo il contratto, non l'implementazione.

**Perché ci interessa:** se la UI parla con `SyncRepository` (interfaccia) invece che con `PocketbaseRepository` (implementazione concreta), possiamo in futuro swappare PocketBase con Nearby Connections o qualsiasi altro sistema — e la UI non lo sa nemmeno.

```dart
// INTERFACCIA — il contratto
abstract class SyncRepository {
  Future<void> push(SyncPacket packet);
  Future<SyncPacket?> pull({required String sinceHlc});
}

// IMPLEMENTAZIONE A — per l'MVP
class PocketbaseRepository implements SyncRepository {
  @override Future<void> push(SyncPacket p) async { /* chiama PocketBase */ }
  @override Future<SyncPacket?> pull({required String sinceHlc}) async { /* ... */ }
}

// IMPLEMENTAZIONE B — per la Fase 3, stessa interfaccia
class NearbyRepository implements SyncRepository {
  @override Future<void> push(SyncPacket p) async { /* usa Bluetooth */ }
  @override Future<SyncPacket?> pull({required String sinceHlc}) async { /* ... */ }
}

// Nel resto dell'app usiamo SEMPRE SyncRepository, mai le implementazioni dirette.
// Per cambiare sistema di sync basta cambiare UNA riga nel main.
```

Lo stesso pattern si applica a `Splitter`: c'è un'interfaccia `Splitter` e quattro implementazioni (`EqualSplitter`, `SharesSplitter`, ecc). La schermata di aggiunta spesa usa `Splitter` — non sa quale tipo è attivo.

---

### get_it — Service Locator

**Cos'è:** un registro globale dove si "registrano" le istanze dei servizi al lancio dell'app, e da cui si recuperano ovunque senza passarle a mano attraverso costruttori e widget.

**Perché lo usiamo:** in Flutter, passare dipendenze "a mano" attraverso decine di widget è tedioso e fragile. `get_it` risolve questo con due righe:

```dart
// In main.dart, al lancio:
GetIt.I.registerSingleton<SyncRepository>(PocketbaseRepository(...));

// In qualsiasi punto dell'app, quando serve:
final repo = GetIt.I<SyncRepository>();
// Ottieni sempre la stessa istanza, già configurata.
```

`get_it` è solo un dizionario glorificato: `Map<Type, Object>`. Niente magia. La semplicità è il punto.

---

### Riverpod — Stato Reattivo della UI

**Cos'è:** un sistema per gestire lo stato della UI in modo reattivo. Quando i dati cambiano, i widget che li mostrano si ricostruiscono automaticamente — senza `setState`, senza `StreamBuilder` nidificati.

**Perché lo usiamo invece di setState:** l'app ha dati che cambiano da fonti diverse (utente, sync PocketBase, sync Nearby). Con `setState` mantenere tutto coerente diventa un incubo. Con Riverpod si definisce la sorgente di verità una volta sola, e la UI la segue.

```dart
// Definisci il provider (sorgente di dati) — di solito in ui/providers/
final groupsProvider = StreamProvider<List<Group>>((ref) {
  // Drift restituisce uno Stream: ogni volta che il DB cambia,
  // tutti i widget che ascoltano questo provider si aggiornano.
  return GetIt.I<AppDatabase>().groupsDao.watchAllGroups();
});

// In un widget:
class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsProvider); // Si ricostruisce quando i gruppi cambiano
    return groups.when(
      data:    (list) => GroupList(list),
      loading: () => const CircularProgressIndicator(),
      error:   (e, _) => Text('Errore: $e'),
    );
  }
}
```

Quando arriva una sync da PocketBase e il DB locale si aggiorna, Drift emette un nuovo valore nello stream → Riverpod lo rileva → la UI si aggiorna. Zero codice extra.

---

### Hybrid Logical Clock (HLC) — Timestamp Sicuri

**Il problema:** due telefoni offline modificano la stessa spesa. Quando si sincronizzano, quale versione vince? Non possiamo usare il timestamp del sistema operativo perché gli orologi dei telefoni possono essere sfasati di secondi o minuti, o addirittura andare indietro (cambio fuso orario, sync NTP, ecc.).

**La soluzione HLC:** un timestamp ibrido che combina l'orologio fisico con un contatore logico. La proprietà chiave è che **non va mai indietro** — anche se il clock del telefono si resetta, l'HLC continua a salire.

**Formato stringa:** `{timestamp_ms_con_padding}:{counter_con_padding}:{node_id}`
- `timestamp_ms`: millisecondi Unix, con padding a 15 cifre (copre date fino al 2286)
- `counter`: si incrementa quando due eventi avvengono nello stesso millisecondo
- `node_id`: identifica quale dispositivo ha generato l'HLC

**Esempio:** `000001738933500123:0002:p5bVpABC...`

Essendo una stringa con padding fisso, SQLite può ordinarla lessicograficamente senza alcun parsing. `WHERE hlc > '000001738933500000:0000:...'` funziona direttamente come query.

#### Cos'è il `node_id` nell'HLC?

Il `node_id` serve per disambiguare quando due dispositivi generano eventi nello stesso millisecondo con lo stesso counter. Deve essere unico per dispositivo e stabile nel tempo.

**Per Smezza usiamo la chiave pubblica Ed25519 dell'utente** (già disponibile come `identity.userId`). È perfetta: è unica globalmente, non cambia mai, e non richiede nessun sistema esterno per generarla.

```dart
// In main.dart, dopo aver caricato l'identità:
final nodeId = identity.userId; // La chiave pubblica Base64URL

// Quando si crea un record:
final hlc = Hlc.now(nodeId, lastKnown: await db.getLastHlc());
```

> **Nota pratica:** nella Fase 1 e 2, l'HLC è "overkill" — basterebbe un semplice `updated_at`. Lo usiamo fin da subito perché il campo è nel DB e il formato è stabilito. Quando arriverà la Fase 3 (P2P tra telefoni senza internet), l'HLC sarà indispensabile e non dovremo fare migrazioni.

---

### Firma Digitale Ed25519 — Integrità dei Dati

**Cos'è:** un algoritmo di firma asimmetrica. Con la chiave privata si "firma" un messaggio; chiunque abbia la chiave pubblica può verificare che il messaggio non sia stato alterato e che sia stato firmato da quel preciso utente.

**Nelle Fasi 1 e 2:** la firma viene generata e storata nel campo `signature` di ogni spesa, ma non viene verificata. Il server (PocketBase) fa da arbitro fidato con le API Rules.

**Nella Fase 3 (P2P):** non c'è un server fidato. Quando Bob riceve una spesa da Alice via Bluetooth, l'unico modo per sapere che Alice l'ha davvero creata — e che nessuno l'ha modificata — è verificare la firma con la chiave pubblica di Alice. Il campo `signature` è già nel DB: basta attivare la verifica nel `MergeEngine`.

```dart
// Cosa si firma: una stringa canonica dei campi immutabili della spesa.
// L'ordine dei campi è fisso — non dipende dalla serializzazione JSON.
final payload = '${expense.id}|${expense.groupId}|${expense.payerId}'
                '|${expense.amount}|${expense.currency}|${expense.hlc}';

// Firma (al momento della creazione):
final signature = await Signer.sign(payload, identity.privateKeyB64);

// Verifica (Fase 3, al momento della ricezione da un peer):
final valid = await Signer.verify(
  payload:      payload,
  signatureB64: expense.signature!,
  publicKeyB64: expense.payerId, // Il payerId È la chiave pubblica dell'utente
);
if (!valid) return; // Scarta il record — qualcuno ha manomesso i dati
```

---

## Stack Tecnologico

| Componente | Tecnologia | Note |
| :--- | :--- | :--- |
| Framework | Flutter + Dart | Cross-platform Android/iOS |
| Database locale | SQLite via **Drift** | Type-safe, reattivo, generato da codice |
| Crittografia | **cryptography** (pub.dev) | Ed25519 — nessuna dipendenza nativa |
| Secure Storage | **flutter_secure_storage** | Chiave privata protetta da biometria/PIN |
| Backend | **PocketBase** (self-hosted) | Leggero, zero config, WebSocket realtime incluso |
| Client PocketBase | **pocketbase** (pub.dev) | SDK Dart ufficiale |
| Stato UI | **Riverpod** | Stream reattivi da Drift → aggiornamento UI automatico |
| Dependency Injection | **get_it** | Registro globale dei servizi — cambia impl. in 1 riga |
| Design | Material 3 + **dynamic_color** | Material You — segue il tema del telefono |
| ID univoci | **uuid** | UUID v4 per gruppi e spese |

---

## Struttura del Progetto

La struttura è divisa in layer con dipendenze **unidirezionali**: `ui` → `domain` → `core`, e `data` implementa `core`. Nessun layer conosce quelli sopra di lui. Questo garantisce che si possa cambiare un'implementazione senza toccare gli altri layer.

```
lib/
├── main.dart                        # Entry point: setup DI + runApp
├── app.dart                         # MaterialApp, router, tema
│
├── core/                            # Logica pura — zero import Flutter/external
│   ├── identity/
│   │   ├── keypair.dart             # Data class: userId, publicKeyB64, privateKeyB64
│   │   └── identity_service.dart    # Genera o carica la coppia di chiavi Ed25519
│   ├── clock/
│   │   └── hlc.dart                 # Hybrid Logical Clock: genera, confronta, serializza
│   ├── crypto/
│   │   └── signer.dart              # Firma e verifica messaggi Ed25519
│   └── sync/
│       ├── sync_repository.dart     # INTERFACCIA astratta — il contratto della sync
│       ├── sync_packet.dart         # Formato dati scambiati (push/pull)
│       └── merge_engine.dart        # Last-Write-Wins basato su HLC
│
├── data/                            # Implementazioni concrete dei contratti di core/
│   ├── local/
│   │   ├── database.dart            # AppDatabase Drift — unico punto di setup
│   │   ├── tables/
│   │   │   ├── users_table.dart
│   │   │   ├── groups_table.dart
│   │   │   ├── expenses_table.dart
│   │   │   └── splits_table.dart
│   │   └── daos/
│   │       ├── users_dao.dart
│   │       ├── groups_dao.dart
│   │       ├── expenses_dao.dart
│   │       └── splits_dao.dart
│   └── remote/
│       ├── noop_repository.dart         # Stub silenzioso (test offline / Fase 1)
│       ├── pocketbase_repository.dart   # MVP: implementa SyncRepository
│       └── nearby_repository.dart       # Fase 3: da implementare
│
├── domain/                          # Regole di business — nessun import Flutter
│   ├── models/
│   │   ├── user.dart
│   │   ├── group.dart
│   │   ├── expense.dart
│   │   └── split.dart
│   ├── splitting/
│   │   ├── splitter.dart            # Interfaccia comune per tutti i tipi di split
│   │   ├── equal_splitter.dart
│   │   ├── exact_splitter.dart
│   │   ├── percent_splitter.dart
│   │   └── shares_splitter.dart
│   └── debt/
│       └── debt_simplifier.dart     # Algoritmo di netting dei debiti
│
└── ui/
    ├── theme/
    │   └── app_theme.dart           # ThemeData M3 + Dynamic Color
    ├── providers/                   # Riverpod providers (stato globale)
    │   ├── auth_provider.dart
    │   ├── groups_provider.dart
    │   ├── expenses_provider.dart
    │   └── sync_provider.dart
    └── screens/
        ├── auth/
        │   ├── login_screen.dart
        │   └── register_screen.dart
        ├── home/                    # Lista gruppi + saldo per valuta
        ├── group_detail/            # Spese + riepilogo debiti
        ├── add_expense/             # Form nuova spesa
        ├── sync/                    # UI Host/Client per Fase 3
        └── settings/                # Profilo, recovery kit, preferenze
```

---

## Schema Database Locale (Drift)

> **Regola d'oro:** non si cancella mai nulla. Soft delete su tutti i record — `is_deleted = true` + HLC aggiornato. Indispensabile per la sync: se cancellassimo fisicamente un record, i peer non saprebbero mai che è stato eliminato.

**Come funziona Drift:** si descrivono le tabelle come classi Dart, si lancia `flutter pub run build_runner build` e Drift genera tutto il codice SQL e i tipi type-safe. Non si scrive SQL a mano.

### `data/local/tables/users_table.dart`
```dart
import 'package:drift/drift.dart';

class UsersTable extends Table {
  // La chiave pubblica Ed25519 in Base64URL è l'ID — stabile per sempre.
  // Non è un UUID generato casualmente: deriva dalla crittografia, è univoca globalmente.
  TextColumn get id          => text()();
  TextColumn get name        => text()();
  BoolColumn get isMe        => boolean().withDefault(const Constant(false))();
  // HLC: "000001738933500123:0002:p5bVpABC..." — vedi sezione HLC per il formato
  TextColumn get hlc         => text()();
  BoolColumn get isDeleted   => boolean().withDefault(const Constant(false))();
  // Credenziali PocketBase — null finché l'utente non fa login
  TextColumn get pbId        => text().nullable()();
  TextColumn get email       => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
```

### `data/local/tables/groups_table.dart`
```dart
class GroupsTable extends Table {
  TextColumn get id            => text()();   // UUID v4
  TextColumn get name          => text()();
  TextColumn get currencyCode  => text()();   // "EUR", "JPY", ecc.
  TextColumn get ownerId       => text()();   // FK → users.id
  TextColumn get hlc           => text()();
  BoolColumn get isDeleted     => boolean().withDefault(const Constant(false))();
  // false = questo record non è ancora stato inviato al server/peer
  BoolColumn get isSynced      => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
```

### `data/local/tables/expenses_table.dart`
```dart
class ExpensesTable extends Table {
  TextColumn get id           => text()();   // UUID v4
  TextColumn get groupId      => text()();   // FK → groups.id
  TextColumn get payerId      => text()();   // FK → users.id — chi ha pagato
  TextColumn get description  => text()();
  RealColumn get amount       => real()();
  TextColumn get currencyCode => text()();
  TextColumn get splitType    => text()();   // EQUAL | EXACT | PERCENT | SHARES
  // Firma Ed25519 del payload canonico della spesa.
  // Generata sempre al momento della creazione/modifica.
  // Verificata obbligatoriamente solo in Fase 3 (P2P) — in Fase 1/2 è storata ma ignorata.
  TextColumn get signature    => text().nullable()();
  TextColumn get hlc          => text()();
  BoolColumn get isDeleted    => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced     => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
```

### `data/local/tables/splits_table.dart`
```dart
class SplitsTable extends Table {
  TextColumn get id               => text()();   // UUID v4
  TextColumn get expenseId        => text()();   // FK → expenses.id
  TextColumn get userId           => text()();   // FK → users.id
  // Importo finale calcolato (es. 33.33 €) — quello che conta per i debiti
  RealColumn get calculatedAmount => real()();
  // Valore di input grezzo: 2 (quote), 50.0 (%), 15.00 (importo esatto)
  // Serve per mostrare e modificare la spesa in un secondo momento
  RealColumn get rawValue         => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
```

### `data/local/database.dart`
```dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

part 'database.g.dart'; // Generato da build_runner — non modificare a mano

@DriftDatabase(
  tables: [UsersTable, GroupsTable, ExpensesTable, SplitsTable],
  daos:   [UsersDao, GroupsDao, ExpensesDao, SplitsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1; // Incrementa ogni volta che cambi le tabelle

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // Esempio: aggiungere una colonna in v2 senza perdere dati
      // if (from < 2) await m.addColumn(expensesTable, expensesTable.newField);
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir  = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'smezza.db'));
    return NativeDatabase(file);
  });
}
```

---

## Il Pattern DAO (Data Access Object)

Un DAO incapsula tutte le query per una tabella. La UI e il domain non toccano mai Drift direttamente — parlano con il DAO. Questo isola le query in un posto solo.

**Pattern generico:** ogni DAO ha le operazioni di base + le query specifiche per quella entità. Le query che restituiscono `Stream` si aggiornano automaticamente quando il DB cambia (integrazione Drift + Riverpod).

```dart
// Pattern generico applicabile a ogni tabella
@DriftAccessor(tables: [NomeTabella])
class NomeDao extends DatabaseAccessor<AppDatabase> with _$NomeDaoMixin {
  NomeDao(super.db);

  // Leggi tutti (come Stream reattivo — Riverpod lo ascolta)
  Stream<List<NomeTableData>> watchAll() => select(nomeTable).watch();

  // Leggi tutti (una tantum, non reattivo)
  Future<List<NomeTableData>> getAll() => select(nomeTable).get();

  // Upsert: inserisce se non esiste, aggiorna se esiste
  Future<void> upsert(NomeTableCompanion entry) =>
      into(nomeTable).insertOnConflictUpdate(entry);

  // Soft delete: non rimuove il record, lo marca come eliminato
  Future<void> softDelete(String id, String newHlc) =>
      (update(nomeTable)..where((t) => t.id.equals(id)))
          .write(NomeTableCompanion(isDeleted: Value(true), hlc: Value(newHlc)));

  // Recupera i record non ancora sincronizzati con il server
  Future<List<NomeTableData>> getUnsynced() =>
      (select(nomeTable)..where((t) => t.isSynced.equals(false))).get();
}
```

**Esempio concreto — `ExpensesDao`:**

```dart
@DriftAccessor(tables: [ExpensesTable, SplitsTable])
class ExpensesDao extends DatabaseAccessor<AppDatabase> with _$ExpensesDaoMixin {
  ExpensesDao(super.db);

  // Tutte le spese di un gruppo, ordinate per HLC decrescente (più recenti prima)
  Stream<List<ExpensesTableData>> watchByGroup(String groupId) =>
      (select(expensesTable)
        ..where((t) => t.groupId.equals(groupId) & t.isDeleted.equals(false))
        ..orderBy([(t) => OrderingTerm.desc(t.hlc)]))
      .watch();

  // Calcola il saldo netto di ogni utente in un gruppo (per la schermata debiti)
  // Restituisce: mappa userId → saldo (positivo = creditore, negativo = debitore)
  Future<Map<String, double>> getNetBalances(String groupId) async {
    // 1. Prendi tutte le spese non eliminate del gruppo
    final expenses = await (select(expensesTable)
      ..where((t) => t.groupId.equals(groupId) & t.isDeleted.equals(false)))
      .get();

    final balances = <String, double>{};

    for (final expense in expenses) {
      // Chi ha pagato riceve credito per l'intero importo
      balances[expense.payerId] = (balances[expense.payerId] ?? 0) + expense.amount;

      // Ogni partecipante viene addebitato della propria quota
      final splits = await (select(splitsTable)
        ..where((t) => t.expenseId.equals(expense.id)))
        .get();
      for (final split in splits) {
        balances[split.userId] = (balances[split.userId] ?? 0) - split.calculatedAmount;
      }
    }
    return balances;
  }
}
```

---

## Identità Crittografica

### `core/identity/keypair.dart`
```dart
/// Rappresenta l'identità crittografica dell'utente su questo dispositivo.
/// userId == publicKeyB64: la chiave pubblica È l'identificatore univoco.
class KeyPair {
  final String userId;         // = publicKeyB64. Usato come users.id nel DB.
  final String publicKeyB64;   // Condiviso con il server e i peer. Base64URL (~44 char).
  final String privateKeyB64;  // MAI lasciare il dispositivo. MAI loggare. MAI inviare.

  const KeyPair({
    required this.userId,
    required this.publicKeyB64,
    required this.privateKeyB64,
  });
}
```

### `core/identity/identity_service.dart`
```dart
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'keypair.dart';

/// Gestisce la generazione e il caricamento dell'identità crittografica.
///
/// flutter_secure_storage salva i dati in:
/// - Android: EncryptedSharedPreferences (protetto da Android Keystore)
/// - iOS: Keychain (protetto da Secure Enclave se disponibile)
/// L'utente può configurare l'accesso biometrico nelle impostazioni del telefono.
class IdentityService {
  static const _storage = FlutterSecureStorage();
  static const _kPriv   = 'smezza_private_key';
  static const _kPub    = 'smezza_public_key';

  /// Carica le chiavi esistenti o ne genera una nuova coppia.
  /// Da chiamare UNA SOLA VOLTA in main() — il risultato viene iniettato via get_it.
  static Future<KeyPair> loadOrCreate() async {
    final priv = await _storage.read(key: _kPriv);
    final pub  = await _storage.read(key: _kPub);
    if (priv != null && pub != null) {
      return KeyPair(userId: pub, publicKeyB64: pub, privateKeyB64: priv);
    }
    return _generateAndStore();
  }

  static Future<KeyPair> _generateAndStore() async {
    final algo   = Ed25519();
    final kp     = await algo.newKeyPair();
    final pubKey = await kp.extractPublicKey();
    // Base64URL: sicuro per database, URL e QR code (nessun carattere problematico)
    final privB64 = base64Url.encode(await kp.extractPrivateKeyBytes());
    final pubB64  = base64Url.encode(pubKey.bytes);
    await _storage.write(key: _kPriv, value: privB64);
    await _storage.write(key: _kPub,  value: pubB64);
    return KeyPair(userId: pubB64, publicKeyB64: pubB64, privateKeyB64: privB64);
  }
}
```

---

## Hybrid Logical Clock

### `core/clock/hlc.dart`
```dart
/// Timestamp ibrido che non va mai indietro, anche tra dispositivi con orologi sfasati.
///
/// Formato stringa (ordinabile lessicograficamente in SQLite):
///   "000001738933500123:0002:p5bVpABC..."
///    ^^^^^^^^^^^^^^^^^ ^^^^ ^^^^^^^^^^^^
///    timestamp ms      cnt  nodeId (= userId/publicKey)
///
/// Il padding fisso (15 cifre per ms, 4 per counter) garantisce che SQLite possa
/// ordinare e filtrare le stringhe HLC senza alcun parsing.
class Hlc implements Comparable<Hlc> {
  final int    timestampMs;
  final int    counter;
  final String nodeId; // = identity.userId (chiave pubblica Base64URL)

  const Hlc({required this.timestampMs, required this.counter, required this.nodeId});

  /// Genera un nuovo HLC per un evento locale (creazione o modifica di un record).
  /// [lastKnown]: l'HLC più recente presente nel DB locale.
  /// Passa null se il DB è vuoto (primo avvio).
  factory Hlc.now(String nodeId, {Hlc? lastKnown}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (lastKnown == null || now > lastKnown.timestampMs) {
      return Hlc(timestampMs: now, counter: 0, nodeId: nodeId);
    }
    // Il clock locale è indietro rispetto all'ultimo evento conosciuto.
    // Mantieni il timestamp dell'ultimo evento e incrementa il counter.
    // Questo garantisce causalità anche con orologio sfasato.
    return Hlc(timestampMs: lastKnown.timestampMs, counter: lastKnown.counter + 1, nodeId: nodeId);
  }

  /// Da usare quando si riceve un HLC da un peer o dal server.
  /// Aggiorna il clock locale per non tornare mai indietro.
  factory Hlc.receive(Hlc remote, String localNodeId, {Hlc? localLast}) {
    final now   = DateTime.now().millisecondsSinceEpoch;
    final maxTs = [now, remote.timestampMs, localLast?.timestampMs ?? 0]
        .reduce((a, b) => a > b ? a : b);
    int counter = 0;
    if (maxTs == remote.timestampMs && maxTs == (localLast?.timestampMs ?? -1)) {
      counter = [remote.counter, localLast?.counter ?? -1].reduce((a, b) => a > b ? a : b) + 1;
    } else if (maxTs == remote.timestampMs) {
      counter = remote.counter + 1;
    } else if (maxTs == localLast?.timestampMs) {
      counter = (localLast?.counter ?? 0) + 1;
    }
    return Hlc(timestampMs: maxTs, counter: counter, nodeId: localNodeId);
  }

  @override
  String toString() =>
      '${timestampMs.toString().padLeft(15, '0')}:${counter.toString().padLeft(4, '0')}:$nodeId';

  factory Hlc.fromString(String s) {
    final parts = s.split(':');
    return Hlc(
      timestampMs: int.parse(parts[0]),
      counter:     int.parse(parts[1]),
      // nodeId può contenere ':' perché è Base64URL — ricomponiamo tutto dopo il secondo ':'
      nodeId: parts.sublist(2).join(':'),
    );
  }

  @override
  int compareTo(Hlc other) => toString().compareTo(other.toString());

  bool operator >(Hlc other)  => compareTo(other) > 0;
  bool operator <(Hlc other)  => compareTo(other) < 0;
  bool operator >=(Hlc other) => compareTo(other) >= 0;
}
```

---

## Firma dei Messaggi

### `core/crypto/signer.dart`
```dart
import 'package:cryptography/cryptography.dart';
import 'dart:convert';

/// Firma e verifica messaggi con Ed25519.
///
/// Nelle Fasi 1 e 2: si chiama solo sign() al momento della creazione/modifica
/// di una spesa. La firma viene storata nel campo signature del DB.
///
/// Nella Fase 3 (P2P): si chiama verify() nel MergeEngine prima di accettare
/// qualsiasi dato da un peer. Se la firma non è valida, il record viene scartato.
class Signer {
  static final _algorithm = Ed25519();

  /// Firma un payload con la chiave privata dell'utente.
  /// Restituisce la firma in Base64URL.
  static Future<String> sign(String payload, String privateKeyB64) async {
    final privBytes = base64Url.decode(privateKeyB64);
    final keyPair   = await _algorithm.newKeyPairFromSeed(privBytes);
    final signature = await _algorithm.sign(utf8.encode(payload), keyPair: keyPair);
    return base64Url.encode(signature.bytes);
  }

  /// Verifica che il payload non sia stato alterato e che la firma appartenga
  /// al possessore della chiave pubblica indicata.
  /// Restituisce false (invece di lanciare) per qualsiasi errore.
  static Future<bool> verify({
    required String payload,
    required String signatureB64,
    required String publicKeyB64,
  }) async {
    try {
      final pubBytes  = base64Url.decode(publicKeyB64);
      final sigBytes  = base64Url.decode(signatureB64);
      final publicKey = SimplePublicKey(pubBytes, type: KeyPairType.ed25519);
      final signature = Signature(sigBytes, publicKey: publicKey);
      return await _algorithm.verify(utf8.encode(payload), signature: signature);
    } catch (_) {
      return false; // Dati malformati = firma non valida
    }
  }

  /// Costruisce il payload canonico da firmare per una spesa.
  /// I campi sono in ordine fisso — non dipende dalla serializzazione JSON,
  /// che può variare in base all'implementazione e all'ordine delle chiavi.
  static String expensePayload(Map<String, dynamic> expense) =>
      '${expense['id']}|${expense['groupId']}|${expense['payerId']}'
      '|${expense['amount']}|${expense['currencyCode']}|${expense['hlc']}';
}
```

---

## Il Pattern Interfaccia + Implementazioni

Questo è il pattern centrale dell'intera architettura. Si applica a `SyncRepository`, `Splitter`, e in futuro a qualsiasi componente che potrebbe avere più implementazioni.

**Struttura:**
1. **Interfaccia** (`abstract class`) — definisce il contratto, vive in `core/`
2. **Implementazione stub** — non fa nulla, usata per test e Fase 1
3. **Implementazione reale A** — per l'MVP
4. **Implementazione reale B** — per la Fase successiva

```
abstract class SyncRepository          ← core/sync/sync_repository.dart
       │
       ├── NoopRepository             ← data/remote/noop_repository.dart (stub)
       ├── PocketbaseRepository       ← data/remote/pocketbase_repository.dart (MVP)
       └── NearbyRepository           ← data/remote/nearby_repository.dart (Fase 3)
```

### `core/sync/sync_repository.dart`
```dart
import 'sync_packet.dart';

/// Contratto che tutte le implementazioni di sync devono rispettare.
/// Il resto dell'app usa SOLO questa interfaccia.
abstract class SyncRepository {
  /// Invia i record locali non ancora sincronizzati.
  Future<void> push(SyncPacket packet);

  /// Scarica i record modificati dopo [sinceHlc].
  /// Restituisce null se non c'è connessione disponibile — non lancia eccezioni.
  Future<SyncPacket?> pull({required String sinceHlc});

  /// Stream per mostrare lo stato della connessione in UI.
  Stream<SyncStatus> get statusStream;

  /// Libera le risorse (connessioni, sottoscrizioni) quando non serve più.
  Future<void> dispose();
}

enum SyncStatus { connected, syncing, disconnected, error }
```

### Implementazione stub — `data/remote/noop_repository.dart`
```dart
/// Non fa nulla, non lancia eccezioni, non logga.
/// Usata quando si vuole sviluppare/testare senza un server disponibile.
class NoopRepository implements SyncRepository {
  @override Future<void>       push(SyncPacket p) async => {};
  @override Future<SyncPacket?> pull({required String sinceHlc}) async => null;
  @override Stream<SyncStatus>  get statusStream => Stream.value(SyncStatus.disconnected);
  @override Future<void>        dispose() async => {};
}
```

### Schema dell'implementazione PocketBase

```dart
class PocketbaseRepository implements SyncRepository {
  // Stato interno
  final PocketBase  _pb;
  final MergeEngine _merge;
  final KeyPair     _identity;
  final _statusCtrl = StreamController<SyncStatus>.broadcast();

  PocketbaseRepository({required String pbUrl, required MergeEngine merge, required KeyPair identity})
      : _pb = PocketBase(pbUrl), _merge = merge, _identity = identity;

  // Autenticazione
  Future<void> login(String email, String password) async { ... }
  Future<void> register(String email, String password, String name) async { ... }
  bool get isLoggedIn => _pb.authStore.isValid;

  // SyncRepository contract
  @override Future<void>        push(SyncPacket p) async { ... }  // Upsert su PocketBase
  @override Future<SyncPacket?> pull({required String sinceHlc}) async { ... } // GET con filtro HLC
  @override Stream<SyncStatus>  get statusStream => _statusCtrl.stream;
  @override Future<void>        dispose() async { ... }

  // Extra: WebSocket realtime (solo PocketBase)
  Future<void> subscribeRealtime() async { ... }
}
```

---

## Il Pattern Splitter

Stesso concetto di `SyncRepository`, applicato ai tipi di divisione delle spese.

```
abstract class Splitter                 ← domain/splitting/splitter.dart
       │
       ├── EqualSplitter               ← parti uguali
       ├── ExactSplitter               ← importi fissi
       ├── PercentSplitter             ← percentuali
       └── SharesSplitter              ← quote proporzionali
```

### `domain/splitting/splitter.dart`
```dart
/// Interfaccia comune per tutti i tipi di divisione.
/// Il form di aggiunta spesa usa Splitter — non sa quale tipo è attivo.
abstract class Splitter {
  /// Calcola le quote. INVARIANTE: la somma dei valori restituiti
  /// deve essere esattamente uguale a [totalAmount] (gestire i centesimi di resto).
  ///
  /// [userIds]: lista degli ID degli utenti coinvolti nella spesa.
  /// [rawValues]: valori di input grezzi (quote, percentuali, importi).
  ///              Null per EqualSplitter (non servono input aggiuntivi).
  Map<String, double> calculate({
    required double totalAmount,
    required List<String> userIds,
    Map<String, double>? rawValues,
  });
}

/// Factory: restituisce il Splitter corretto dato il tipo come stringa.
/// Usato per deserializzare le spese dal DB.
Splitter splitterFor(String splitType) => switch (splitType) {
  'EQUAL'   => EqualSplitter(),
  'EXACT'   => ExactSplitter(),
  'PERCENT' => PercentSplitter(),
  'SHARES'  => SharesSplitter(),
  _         => throw ArgumentError('SplitType sconosciuto: $splitType'),
};
```

### Esempio completo — `EqualSplitter`
```dart
/// Divide il totale in parti uguali.
/// Il resto dei centesimi va al primo utente della lista.
class EqualSplitter implements Splitter {
  @override
  Map<String, double> calculate({
    required double totalAmount,
    required List<String> userIds,
    Map<String, double>? rawValues, // Non usato per EQUAL
  }) {
    assert(userIds.isNotEmpty, 'Servono almeno 2 utenti');
    final n          = userIds.length;
    // Lavoriamo in centesimi interi per evitare errori di arrotondamento floating point
    final totalCents = (totalAmount * 100).round();
    final baseCents  = totalCents ~/ n;        // Quota base (divisione intera)
    final remainder  = totalCents % n;          // Centesimi di resto
    return {
      for (var i = 0; i < n; i++)
        // Il primo utente si prende il resto (es. 10.01€ / 3 → 3.34 + 3.33 + 3.33)
        userIds[i]: (baseCents + (i == 0 ? remainder : 0)) / 100.0,
    };
  }
}
```

### Esempio completo — `SharesSplitter`
```dart
/// Divide il totale in proporzione a quote assegnate.
/// Utile per: famiglie (adulti 2 quote, bambini 1), hotel (singola/doppia), ecc.
class SharesSplitter implements Splitter {
  @override
  Map<String, double> calculate({
    required double totalAmount,
    required List<String> userIds,
    Map<String, double>? rawValues, // Obbligatorio: mappa userId → numero di quote
  }) {
    assert(rawValues != null && rawValues.isNotEmpty, 'SharesSplitter richiede rawValues');
    final totalShares = rawValues!.values.fold(0.0, (a, b) => a + b);
    assert(totalShares > 0, 'La somma delle quote deve essere positiva');
    final totalCents = (totalAmount * 100).round();
    int   assigned   = 0;
    final result     = <String, double>{};
    for (var i = 0; i < userIds.length; i++) {
      final uid = userIds[i];
      if (i == userIds.length - 1) {
        // L'ultimo prende il resto per garantire che la somma sia esatta al centesimo
        result[uid] = (totalCents - assigned) / 100.0;
      } else {
        final cents = (totalCents * (rawValues[uid] ?? 0) / totalShares).round();
        result[uid] = cents / 100.0;
        assigned   += cents;
      }
    }
    return result;
  }
}
```

---

## Algoritmo di Semplificazione dei Debiti

### `domain/debt/debt_simplifier.dart`
```dart
/// Riduce al minimo il numero di pagamenti per saldare tutti i debiti nel gruppo.
///
/// Esempio: A deve 5€ a B, B deve 3€ a C, C deve 2€ a A.
/// Senza semplificazione: 3 pagamenti.
/// Con semplificazione: A paga 3€ a B, A paga 2€ a C → 2 pagamenti.
///
/// IMPORTANTE: eseguire separatamente per ogni valuta.
/// I debiti in EUR e JPY non si mescolano mai.
class DebtSimplifier {
  /// [netBalances]: mappa userId → saldo netto.
  ///   Positivo = creditore (ti devono soldi).
  ///   Negativo = debitore (devi soldi).
  ///   Calcolato dal DAO come: somma_pagato - somma_quote.
  static List<Settlement> simplify(Map<String, double> netBalances) {
    // Convertiamo in centesimi interi per evitare errori floating point
    final balances  = netBalances.map((k, v) => MapEntry(k, (v * 100).round()));
    // Ordina creditori dal più grande, debitori dal più negativo
    final creditors = balances.entries.where((e) => e.value > 0).toList()
                        ..sort((a, b) => b.value.compareTo(a.value));
    final debtors   = balances.entries.where((e) => e.value < 0).toList()
                        ..sort((a, b) => a.value.compareTo(b.value));
    final mCred     = creditors.map((e) => [e.key, e.value]).toList();
    final mDebt     = debtors.map((e)   => [e.key, e.value]).toList();
    final result    = <Settlement>[];

    int ci = 0, di = 0;
    while (ci < mCred.length && di < mDebt.length) {
      // Quanto può pagare il debitore corrente al creditore corrente?
      final amount = (mCred[ci][1] as int) < -(mDebt[di][1] as int)
          ? mCred[ci][1] as int     // Il creditore si satura prima
          : -(mDebt[di][1] as int); // Il debitore si satura prima
      result.add(Settlement(
        from: mDebt[di][0] as String,
        to:   mCred[ci][0] as String,
        amountCents: amount,
      ));
      mCred[ci][1] = (mCred[ci][1] as int) - amount;
      mDebt[di][1] = (mDebt[di][1] as int) + amount;
      // Avanza al prossimo creditore/debitore se il corrente è a zero
      if ((mCred[ci][1] as int) == 0) ci++;
      if ((mDebt[di][1] as int) == 0) di++;
    }
    return result;
  }
}

class Settlement {
  final String from;         // Chi deve pagare
  final String to;           // Chi deve ricevere
  final int    amountCents;  // Importo in centesimi (evita float)
  double get amount => amountCents / 100.0;
  const Settlement({required this.from, required this.to, required this.amountCents});
}
```

---

## Astrazione della Sincronizzazione

### `core/sync/sync_packet.dart`
```dart
import 'dart:convert';

/// Unità di trasferimento dati tra dispositivi.
/// Stesso formato per PocketBase e Nearby — il MergeEngine non distingue la sorgente.
class SyncPacket {
  final String senderUserId;
  final String sinceHlc;    // HLC di partenza usato per il pull (utile per debug)
  final List<Map<String, dynamic>> users;
  final List<Map<String, dynamic>> groups;
  final List<Map<String, dynamic>> expenses;
  final List<Map<String, dynamic>> splits;

  const SyncPacket({
    required this.senderUserId,
    required this.sinceHlc,
    this.users = const [], this.groups = const [],
    this.expenses = const [], this.splits = const [],
  });

  bool get isEmpty => users.isEmpty && groups.isEmpty && expenses.isEmpty && splits.isEmpty;

  String toJsonString() => jsonEncode({
    'senderUserId': senderUserId, 'sinceHlc': sinceHlc,
    'users': users, 'groups': groups, 'expenses': expenses, 'splits': splits,
  });

  factory SyncPacket.fromJsonString(String s) {
    final j = jsonDecode(s);
    return SyncPacket(
      senderUserId: j['senderUserId'], sinceHlc: j['sinceHlc'],
      users:    List<Map<String, dynamic>>.from(j['users']    ?? []),
      groups:   List<Map<String, dynamic>>.from(j['groups']   ?? []),
      expenses: List<Map<String, dynamic>>.from(j['expenses'] ?? []),
      splits:   List<Map<String, dynamic>>.from(j['splits']   ?? []),
    );
  }
}
```

### `core/sync/merge_engine.dart`
```dart
/// Applica i record ricevuti da un peer/server al DB locale con Last-Write-Wins su HLC.
/// Usato sia dopo un pull da PocketBase che dopo una ricezione da Nearby.
/// La sorgente dei dati non importa — il MergeEngine è agnostico.
class MergeEngine {
  final AppDatabase _db;
  MergeEngine(this._db);

  /// Applica un SyncPacket al DB locale in una singola transazione.
  /// Se qualcosa va storto, tutta la transazione viene annullata.
  Future<void> applyPacket(SyncPacket packet) async {
    await _db.transaction(() async {
      for (final u in packet.users)    await _mergeRecord('users',    u);
      for (final g in packet.groups)   await _mergeRecord('groups',   g);
      for (final e in packet.expenses) await _mergeRecord('expenses', e);
      for (final s in packet.splits)   await _mergeSplit(s); // I split non hanno HLC proprio
    });
  }

  Future<void> _mergeRecord(String table, Map<String, dynamic> remote) async {
    final localHlc = await _db.getHlc(table, remote['id'] as String);
    // Se il record remoto è più vecchio di quello locale, ignoralo
    if (!_shouldUpdate(localHlc: localHlc, remoteHlc: remote['hlc'] as String)) return;
    await _db.upsert(table, remote);
  }

  Future<void> _mergeSplit(Map<String, dynamic> remote) async {
    // I split sono immutabili: se l'ID non esiste, inserisci; altrimenti ignora.
    // Non hanno HLC perché cambiano solo quando cambia la spesa padre.
    final exists = await _db.splitsDao.exists(remote['id'] as String);
    if (!exists) await _db.splitsDao.upsert(SplitsTableCompanion.fromJson(remote));
  }

  static bool _shouldUpdate({required String? localHlc, required String remoteHlc}) {
    if (localHlc == null) return true; // Nuovo record: inserisci sempre
    return Hlc.fromString(remoteHlc) > Hlc.fromString(localHlc);
  }
}
```

---

## Dependency Injection (main.dart)

```dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
// ... altri import

final sl = GetIt.instance; // Accessibile globalmente come sl<Tipo>()

Future<void> _setupDependencies() async {
  // 1. Identità: carica dal secure storage o genera al primo avvio
  final identity = await IdentityService.loadOrCreate();
  sl.registerSingleton<KeyPair>(identity);

  // 2. Database locale
  final db = AppDatabase();
  sl.registerSingleton<AppDatabase>(db);

  // 3. Merge engine (dipende dal DB)
  sl.registerSingleton<MergeEngine>(MergeEngine(db));

  // 4. Sync repository ← CAMBIA QUESTA RIGA PER PASSARE DA UNA FASE ALL'ALTRA
  //
  // Fase 1 (offline, nessun server):
  //   sl.registerSingleton<SyncRepository>(NoopRepository());
  //
  // MVP (PocketBase):
  sl.registerSingleton<SyncRepository>(PocketbaseRepository(
    pbUrl:    'http://TUO_IP:8090', // IP del tuo server home
    merge:    sl<MergeEngine>(),
    identity: sl<KeyPair>(),
  ));
  //
  // Fase 3 (Nearby, aggiunto a PocketBase o in sostituzione):
  //   sl.registerSingleton<SyncRepository>(NearbyRepository(
  //     merge: sl<MergeEngine>(), identity: sl<KeyPair>(),
  //   ));
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _setupDependencies();
  runApp(const ProviderScope(child: SmezzaApp())); // ProviderScope richiesto da Riverpod
}
```

---

## Setup PocketBase

### Struttura delle collezioni

Crea queste 4 collezioni. Tutte usano l'ID interno di PocketBase come chiave primaria, ma hanno un campo `uuid` che è il nostro ID applicativo (per la simmetria con il DB locale).

| Collezione | Campi da aggiungere |
| :--- | :--- |
| `smz_users` | `uuid` (text, unique, required), `name` (text), `public_key` (text), `hlc` (text), `is_deleted` (bool) |
| `smz_groups` | `uuid`, `name`, `currency_code`, `owner_uuid`, `hlc`, `is_deleted` |
| `smz_expenses` | `uuid`, `group_uuid`, `payer_uuid`, `description`, `amount` (number), `currency_code`, `split_type`, `signature` (text), `hlc`, `is_deleted` |
| `smz_splits` | `uuid`, `expense_uuid`, `user_uuid`, `calculated_amount` (number), `raw_value` (number, optional) |

### API Rules

Impostare su ogni collezione per proteggere i dati degli utenti. La sintassi è quella di PocketBase.

```
// smz_expenses — chi può leggere una spesa?
// Solo se l'utente autenticato è membro del gruppo (ha almeno uno split in quella spesa)
@collection.smz_splits.user_uuid ?= @request.auth.uuid

// smz_groups — chi può leggere un gruppo?  
// Solo il creatore o chi ha spese nel gruppo
owner_uuid = @request.auth.uuid ||
@collection.smz_expenses.smz_splits_via_expense_uuid.user_uuid ?= @request.auth.uuid

// Regola di scrittura per smz_expenses (create/update)
// Solo il pagante può creare/modificare la spesa
payer_uuid = @request.auth.uuid
```

---

## `pubspec.yaml`

```yaml
name: smezza
description: Gestione spese di gruppo — local-first con sync PocketBase

environment:
  sdk: '>=3.3.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # Database locale
  drift: ^2.18.0
  sqlite3_flutter_libs: ^0.5.0   # Driver SQLite nativo per Android/iOS
  path_provider: ^2.1.4
  path: ^1.9.0

  # Crittografia — identità Ed25519 + firma messaggi
  cryptography: ^2.7.0
  flutter_secure_storage: ^9.2.2  # Chiave privata nel keychain/keystore del telefono

  # Backend
  pocketbase: ^0.20.0             # SDK Dart ufficiale per PocketBase

  # Stato e DI
  flutter_riverpod: ^2.5.1        # Stato reattivo UI
  riverpod_annotation: ^2.3.5     # Opzionale: genera il boilerplate dei provider
  get_it: ^7.6.7                  # Service locator per le dipendenze di core/data

  # UI
  dynamic_color: ^1.7.0           # Material You — colori dal wallpaper

  # Utilities
  uuid: ^4.4.0                    # UUID v4 per groups e expenses
  shared_preferences: ^2.2.3      # Persiste last_sync_hlc tra riavvii

dev_dependencies:
  drift_dev: ^2.18.0              # Generatore codice Drift
  build_runner: ^2.4.10           # Runner per la generazione codice
  riverpod_generator: ^2.4.0      # Opzionale: generatore provider Riverpod
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
```

---

## Roadmap MVP — Task per 2-3 Persone

Ogni modulo è **indipendente**: si può sviluppare in parallelo senza conflitti di merge. Assegna un modulo per persona.

### Modulo A — Fondamenta (1 persona, ~2 giorni)
Blocca tutti gli altri — va fatto per primo.

- [ ] **A1** Setup progetto Flutter, `pubspec.yaml`, struttura cartelle
- [ ] **A2** Tabelle Drift + `database.dart` + primo `build_runner`
- [ ] **A3** `IdentityService` + `KeyPair` + test unitari
- [ ] **A4** `Hlc` + test unitari (casi limite: orologio indietro, stesso timestamp)
- [ ] **A5** `SyncRepository` (interfaccia) + `SyncPacket` + `MergeEngine` + `NoopRepository`
- [ ] **A6** `main.dart` con DI via `get_it` (usa `NoopRepository` per ora)

### Modulo B — Logica di Business (1 persona, ~2 giorni)
Dipende da A2. Può partire in parallelo ad A3-A6.

- [ ] **B1** `EqualSplitter` + test (casi arrotondamento: 10€ / 3 persone)
- [ ] **B2** `ExactSplitter` + `PercentSplitter` + test (validazione somma = 100%)
- [ ] **B3** `SharesSplitter` + test (quote frazionarie, resto al centesimo)
- [ ] **B4** `DebtSimplifier` + test (vari scenari debiti ciclici)
- [ ] **B5** DAOs Drift (CRUD + `getNetBalances` + `watchByGroup`)

### Modulo C — UI Base (1 persona, ~3 giorni)
Dipende da A6 e B5.

- [ ] **C1** `app_theme.dart` + Dynamic Color
- [ ] **C2** HomeScreen: lista gruppi + saldo totale per valuta
- [ ] **C3** GroupDetailScreen: lista spese + riepilogo debiti
- [ ] **C4** AddExpenseScreen: form con selezione tipo split
- [ ] **C5** Toggle "Semplifica debiti" con visualizzazione Prima/Dopo

### Modulo D — PocketBase + Auth (1-2 persone, ~3 giorni)
Dipende da A5 e A6. Può andare in parallelo a C.

- [ ] **D1** Setup PocketBase sul server (collezioni + API rules)
- [ ] **D2** `PocketbaseRepository` — push + pull
- [ ] **D3** Realtime WebSocket — `subscribeRealtime()`
- [ ] **D4** `SyncService` — orchestratore push/pull
- [ ] **D5** LoginScreen + RegisterScreen
- [ ] **D6** Wiring in `main.dart`: sostituire `NoopRepository` con `PocketbaseRepository`

### Modulo E — Rifinitura MVP (tutti insieme, ~1 giorno)
Dipende da C e D.

- [ ] **E1** Banner stato sync in UI (connesso / sincronizzazione / errore)
- [ ] **E2** Gestione errori e loading states
- [ ] **E3** Test su dispositivi fisici (Android + iOS se possibile)
- [ ] **E4** Fix bug emersi dai test

---

## Cosa viene dopo l'MVP (non adesso)

| Feature | Cosa aggiungere | Impatto sul codice esistente |
| :--- | :--- | :--- |
| Nearby Connections (P2P) | `NearbyRepository` in `data/remote/` | 1 riga in `main.dart` |
| Verifica firma (sicurezza P2P) | Attivare `Signer.verify()` in `MergeEngine._mergeRecord()` | ~5 righe |
| Notifiche push (FCM) | `firebase_messaging` + hook JS in PocketBase | Zero impatto su logica sync |
| Foto scontrini | Campo `receipt_url` in `expenses` + upload PocketBase | 1 migrazione DB, nuova UI |
| Export CSV/JSON | Metodo `exportGroup()` in `ExpensesDao` | Zero impatto altrove |
| Multi-valuta con tasso manuale | Estendere `DebtSimplifier` con conversione opzionale | Zero impatto su sync o UI |

---

> *"Il codice deve trattare il server come un accessorio, non come una necessità. Se il database locale è integro, l'utente deve poter fare tutto."*

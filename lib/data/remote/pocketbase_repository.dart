import 'dart:async';
import 'package:pocketbase/pocketbase.dart';

import '../../sync/sync_packet.dart';
import '../../sync/sync_repository.dart';
import '../../sync/merge_engine.dart';
import '../../core/identity/identity_manager.dart';

class PocketbaseRepository implements SyncRepository {
  final PocketBase _pb;
  final MergeEngine _merge;
  final IdentityService _identity;

  final _statusController = StreamController<SyncStatus>.broadcast();

  PocketbaseRepository({
    required String pbUrl,
    required MergeEngine merge,
    required IdentityService identity,
  }) : _pb = PocketBase(pbUrl),
       _merge = merge,
       _identity = identity {
    _statusController.add(SyncStatus.disconnected);
  }

  @override
  Stream<SyncStatus> get statusStream => _statusController.stream;

  bool get isLoggedIn => _pb.authStore.isValid;

  // Autenticazione di base
  Future<void> login(String email, String password) async {
    _statusController.add(SyncStatus.syncing);
    try {
      await _pb.collection('users').authWithPassword(email, password);
      _statusController.add(SyncStatus.connected);
    } catch (_) {
      _statusController.add(SyncStatus.error);
      rethrow;
    }
  }

  // Registrazione nuovo utente
  Future<void> register(String email, String password, String name) async {
    _statusController.add(SyncStatus.syncing);
    try {
      await _pb
          .collection('users')
          .create(
            body: {
              'email': email,
              'password': password,
              'passwordConfirm': password,
              'name': name,
            },
          );
      // Effettua subito il login dopo essersi registrato
      await login(email, password);
    } catch (_) {
      _statusController.add(SyncStatus.error);
      rethrow;
    }
  }

  @override
  Future<void> push(SyncPacket packet) async {
    // if (!isLoggedIn) return;

    _statusController.add(SyncStatus.syncing);
    try {
      // 1. Spediamo i gruppi
      for (final g in packet.groups) {
        await _pb
            .collection('groups')
            .create(
              body: {
                'id': g['id'], // Usiamo direttamente l'id nativo di PocketBase!
                'name': g['name'],
                'currency_code': g['currencyCode'],
                'owner_id': g['ownerId'],
                'signature': g['signature'], // Inviamo la firma del gruppo
                'hlc': g['hlc'],
                'is_deleted': g['isDeleted'],
              },
            );
      }

      // 2. Spediamo le spese
      for (final e in packet.expenses) {
        await _pb
            .collection('expenses')
            .create(
              body: {
                'id': e['id'],
                'group_id':
                    e['groupId'], // Allineato a 'group_id' di PocketBase
                'creator_id':
                    e['payerId'], // Allineato a 'creator_id' di PocketBase
                'description': e['description'],
                'amount': e['amount'],
                'currency_code': e['currencyCode'],
                'split_type': e['splitType'],
                'signature':
                    e['signature'], // Ora invierà la firma reale creata sopra!
                'hlc': e['hlc'],
                'is_deleted': e['isDeleted'],
              },
            );
      }

      // 3. Spediamo gli split
      for (final s in packet.splits) {
        await _pb
            .collection('expense_splits')
            .create(
              body: {
                'id': s['id'],
                'expense_id': s['expenseId'],
                'user_id': s['userId'],
                'calculated_amount': s['calculatedAmount'],
                'raw_value': s['rawValue'],
              },
            );
      }

      _statusController.add(SyncStatus.connected);
    } catch (e) {
      _statusController.add(SyncStatus.error);
      rethrow; // <--- IMPORTANTE! Rilancia l'errore al SyncService
    }
  }

  @override
  Future<SyncPacket?> pull({required String sinceHlc}) async {
    // if (!isLoggedIn) return null;

    _statusController.add(SyncStatus.syncing);
    try {
      // Chiediamo i record modificati dopo sinceHlc
      final filterQuery = 'hlc > "$sinceHlc"';

      final remoteGroups = await _pb
          .collection('groups')
          .getFullList(filter: filterQuery);
      final remoteExpenses = await _pb
          .collection('expenses')
          .getFullList(filter: filterQuery);

      // 2. Scarichiamo gli split associati alle spese
      final List<RecordModel> remoteSplits = [];
      if (remoteExpenses.isNotEmpty) {
        // Generiamo il filtro unendo le condizioni con '||' (OR):
        // "expense_id = 'id1' || expense_id = 'id2'"
        final filterQuery = remoteExpenses
            .map((e) => 'expense_id = "${e.id}"')
            .join(
              ' || ',
            ); // Unisce le condizioni con l'operatore OR di PocketBase

        remoteSplits.addAll(
          await _pb
              .collection('expense_splits')
              .getFullList(filter: filterQuery),
        );
      }

      // Cambiamo 'uuid' con 'id' nativo nei mappatori del pull
      final groupsJson = remoteGroups
          .map(
            (r) => {
              'id': r.id, // r.id legge l'id nativo di PocketBase
              'name': r.getStringValue('name'),
              'currencyCode': r.getStringValue('currency_code'),
              'ownerId': r.getStringValue('owner_id'),
              'signature': r.getStringValue('signature'), // Riceviamo la firma
              'hlc': r.getStringValue('hlc'),
              'isDeleted': r.getBoolValue('is_deleted'),
              'isSynced': true,
            },
          )
          .toList();

      final expensesJson = remoteExpenses
          .map(
            (r) => {
              'id': r.id,
              'groupId': r.getStringValue('group_id'),
              'payerId': r.getStringValue('creator_id'),
              'description': r.getStringValue('description'),
              'amount': r.getDoubleValue('amount'),
              'currencyCode': r.getStringValue('currency_code'),
              'splitType': r.getStringValue('split_type'),
              'signature': r.getStringValue('signature'),
              'hlc': r.getStringValue('hlc'),
              'isDeleted': r.getBoolValue('is_deleted'),
              'isSynced': true,
            },
          )
          .toList();

      final splitsJson = remoteSplits
          .map(
            (r) => {
              'id': r.id,
              'expenseId': r.getStringValue('expense_id'),
              'userId': r.getStringValue('user_id'),
              'calculatedAmount': r.getDoubleValue('calculated_amount'),
              'rawValue': r.getDoubleValue('raw_value'),
            },
          )
          .toList();

      final packet = SyncPacket(
        senderUserId: _identity.uuid,
        sinceHlc: sinceHlc,
        groups: groupsJson,
        expenses: expensesJson,
        splits: splitsJson,
      );

      // Applichiamo il pacchetto al database locale
      await _merge.applyPacket(packet);

      _statusController.add(SyncStatus.connected);
      return packet;
    } catch (e) {
      _statusController.add(SyncStatus.error);
      rethrow; // <--- IMPORTANTE!
    }
  }

  @override
  Future<void> dispose() async {
    await _statusController.close();
  }
}

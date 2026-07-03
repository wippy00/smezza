import 'dart:async';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../sync/sync_packet.dart';
import '../../sync/sync_repository.dart';
import '../../sync/merge_engine.dart';
import '../../core/identity/identity_manager.dart';
import '../../core/hlc/hlc_manager.dart';

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

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('pb_auth_token');
    final modelStr = prefs.getString('pb_auth_model');

    if (token != null && modelStr != null) {
      try {
        final modelMap = jsonDecode(modelStr);
        final model = RecordModel.fromJson(modelMap);

        _pb.authStore.save(token, model);
        _statusController.add(SyncStatus.connected);
        print(
          "PocketbaseRepository: Sessione utente ripristinata correttamente!",
        );
      } catch (e) {
        print("PocketbaseRepository: Errore nel ripristino della sessione: $e");
        _pb.authStore.clear();
      }
    }
  }

  Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pb_auth_token', _pb.authStore.token);
    await prefs.setString('pb_auth_model', jsonEncode(_pb.authStore.model));
  }

  Future<void> logout() async {
    _pb.authStore.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pb_auth_token');
    await prefs.remove('pb_auth_model');
    _statusController.add(SyncStatus.disconnected);
    print("PocketbaseRepository: Sessione cancellata (Logout).");
  }

  Future<void> login(String email, String password) async {
    _statusController.add(SyncStatus.syncing);
    try {
      await _pb.collection('users').authWithPassword(email, password);
      await _saveSession();
      _statusController.add(SyncStatus.connected);
    } catch (_) {
      _statusController.add(SyncStatus.error);
      rethrow;
    }
  }

  Future<void> register(String email, String password, String name) async {
    _statusController.add(SyncStatus.syncing);
    try {
      final initialHlc = Hlc.now(_identity.uuid);

      await _pb
          .collection('users')
          .create(
            body: {
              'email': email,
              'password': password,
              'passwordConfirm': password,
              'name': name,
              'public_key': _identity.uuid,
              'hlc': initialHlc.toString(),
            },
          );
      await login(email, password);
    } catch (_) {
      _statusController.add(SyncStatus.error);
      rethrow;
    }
  }

  Future<void> _upsertRecord(
    String collection,
    String id,
    Map<String, dynamic> body,
  ) async {
    try {
      await _pb.collection(collection).update(id, body: body);
    } catch (e) {
      if (e is ClientException && e.statusCode == 404) {
        final createBody = Map<String, dynamic>.from(body)..['id'] = id;
        await _pb.collection(collection).create(body: createBody);
      } else {
        rethrow;
      }
    }
  }

  @override
  Future<void> push(SyncPacket packet) async {
    if (!isLoggedIn) return;

    _statusController.add(SyncStatus.syncing);
    try {
      for (final g in packet.groups) {
        await _upsertRecord('groups', g['id'], {
          'name': g['name'],
          'currency_code': g['currencyCode'],
          'owner_id': g['ownerId'],
          'signature': g['signature'],
          'hlc': g['hlc'],
          'is_deleted': g['isDeleted'],
          'member_ids':
              g['memberIds'], // <--- AGGIUNTO IL SYNC DEI PARTECIPANTI VERSO POCKETBASE
        });
      }

      for (final e in packet.expenses) {
        await _upsertRecord('expenses', e['id'], {
          'group_id': e['groupId'],
          'creator_id': e['payerId'],
          'description': e['description'],
          'amount': e['amount'],
          'currency_code': e['currencyCode'],
          'split_type': e['splitType'],
          'signature': e['signature'],
          'hlc': e['hlc'],
          'is_deleted': e['isDeleted'],
        });
      }

      for (final s in packet.splits) {
        await _upsertRecord('expense_splits', s['id'], {
          'expense_id': s['expenseId'],
          'user_id': s['userId'],
          'calculated_amount': s['calculatedAmount'],
          'raw_value': s['rawValue'],
        });
      }

      _statusController.add(SyncStatus.connected);
    } catch (e) {
      _statusController.add(SyncStatus.error);
      rethrow;
    }
  }

  @override
  Future<SyncPacket?> pull({required String sinceHlc}) async {
    if (!isLoggedIn) return null;

    _statusController.add(SyncStatus.syncing);
    try {
      final filterQuery = 'hlc > "$sinceHlc"';

      final remoteGroups = await _pb
          .collection('groups')
          .getFullList(filter: filterQuery);
      final remoteExpenses = await _pb
          .collection('expenses')
          .getFullList(filter: filterQuery);

      final List<RecordModel> remoteSplits = [];
      if (remoteExpenses.isNotEmpty) {
        final expenseUuids = remoteExpenses
            .map((e) => 'expense_id = "${e.id}"')
            .join(' || ');
        remoteSplits.addAll(
          await _pb
              .collection('expense_splits')
              .getFullList(filter: expenseUuids),
        );
      }

      final groupsJson = remoteGroups
          .map(
            (r) => {
              'id': r.id,
              'name': r.getStringValue('name'),
              'currencyCode': r.getStringValue('currency_code'),
              'ownerId': r.getStringValue('owner_id'),
              'signature': r.getStringValue('signature'),
              'hlc': r.getStringValue('hlc'),
              'isDeleted': r.getBoolValue('is_deleted'),
              'memberIds': r.getStringValue(
                'member_ids',
              ), // <--- RICEZIONE MEMBRI DA POCKETBASE
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

      await _merge.applyPacket(packet);

      _statusController.add(SyncStatus.connected);
      return packet;
    } catch (e) {
      _statusController.add(SyncStatus.error);
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    await _statusController.close();
  }
}

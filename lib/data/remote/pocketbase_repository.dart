import 'dart:async';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../sync/sync_packet.dart';
import '../../sync/sync_repository.dart';
import '../../sync/merge_engine.dart';
import '../../core/identity/identity_manager.dart';
import '../../core/hlc/hlc_manager.dart';
import '../../sync/push_result.dart';

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

  String? _encodeDate(int? epochMillis) {
    if (epochMillis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(
      epochMillis,
      isUtc: true,
    ).toIso8601String();
  }

  int? _decodeDate(String raw) {
    if (raw.isEmpty) return null;
    return DateTime.parse(raw).toUtc().millisecondsSinceEpoch;
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

  Future<bool> verifyIdentityMatchesServer(
    String email,
    String password,
  ) async {
    try {
      final authResult = await _pb
          .collection('users')
          .authWithPassword(email, password);
      final remotePubKey = authResult.record.getStringValue('public_key');
      return remotePubKey == _identity.uuid;
    } catch (_) {
      return false;
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
  Future<PushResult> push(SyncPacket packet) async {
    if (!isLoggedIn) return const PushResult();

    _statusController.add(SyncStatus.syncing);

    final succeededGroupIds = <String>{};
    final succeededExpenseIds = <String>{};
    final succeededSplitIds = <String>{};
    final failedGroupErrors = <String, String>{};
    final failedExpenseErrors = <String, String>{};
    final failedSplitErrors = <String, String>{};

    for (final g in packet.groups) {
      final id = g['id'] as String;
      try {
        await _upsertRecord('groups', id, {
          'name': g['name'],
          'currency_code': g['currencyCode'],
          'owner_id': g['ownerId'],
          'signature': g['signature'],
          'hlc': g['hlc'],
          'is_deleted': g['isDeleted'],
          'member_ids': g['memberIds'],
        });
        succeededGroupIds.add(id);
      } catch (err) {
        failedGroupErrors[id] = _describeError(err);
        print('PocketbaseRepository [push]: gruppo $id fallito: $err');
      }
    }

    for (final e in packet.expenses) {
      final id = e['id'] as String;
      try {
        await _upsertRecord('expenses', id, {
          'group_id': e['groupId'],
          'creator_id': e['payerId'],
          'category_id': e['categoryId'],
          'description': e['description'],
          'amount': e['amount'],
          'currency_code': e['currencyCode'],
          'date': _encodeDate(e['date'] as int?),
          'split_type': e['splitType'],
          'signature': e['signature'],
          'hlc': e['hlc'],
          'is_deleted': e['isDeleted'],
        });
        succeededExpenseIds.add(id);
      } catch (err) {
        failedExpenseErrors[id] = _describeError(err);
        print('PocketbaseRepository [push]: spesa $id fallita: $err');
      }
    }

    for (final s in packet.splits) {
      final id = s['id'] as String;
      try {
        await _upsertRecord('expense_splits', id, {
          'expense_id': s['expenseId'],
          'user_id': s['userId'],
          'calculated_amount': s['calculatedAmount'],
          'raw_value': s['rawValue'],
          'hlc': s['hlc'],
          'is_deleted': s['isDeleted'],
        });
        succeededSplitIds.add(id);
      } catch (err) {
        failedSplitErrors[id] = _describeError(err);
        print('PocketbaseRepository [push]: split $id fallito: $err');
      }
    }

    final anyFailure =
        failedGroupErrors.isNotEmpty ||
        failedExpenseErrors.isNotEmpty ||
        failedSplitErrors.isNotEmpty;

    _statusController.add(anyFailure ? SyncStatus.error : SyncStatus.connected);

    return PushResult(
      succeededGroupIds: succeededGroupIds,
      succeededExpenseIds: succeededExpenseIds,
      succeededSplitIds: succeededSplitIds,
      failedGroupErrors: failedGroupErrors,
      failedExpenseErrors: failedExpenseErrors,
      failedSplitErrors: failedSplitErrors,
    );
  }

  // Estrae un messaggio leggibile dall'errore, incluso il dettaglio che PocketBase
  // di solito mette in `response['message']` (quello che hai incollato tu nel log).
  String _describeError(Object err) {
    if (err is ClientException) {
      final message = err.response['message'] as String? ?? err.toString();
      return 'HTTP ${err.statusCode}: $message';
    }
    return err.toString();
  }

  @override
  Future<SyncPacket?> pull({required String sinceHlc}) async {
    if (!isLoggedIn) return null;

    _statusController.add(SyncStatus.syncing);
    try {
      final filterQuery = 'hlc > "$sinceHlc"';

      final remoteUsers = await _pb
          .collection('users')
          .getFullList(filter: filterQuery);
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

      final usersJson = remoteUsers
          .map(
            (r) => {
              'id': r.getStringValue('public_key'),
              'name': r.getStringValue('name'),
              'hlc': r.getStringValue('hlc'),
              'isMe': r.getStringValue('public_key') == _identity.uuid,
              'isDeleted': false,
            },
          )
          .toList();

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
              'memberIds': r.getStringValue('member_ids'),
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
              'categoryId': r.getStringValue('category_id'),
              'description': r.getStringValue('description'),
              'amount': r.getDoubleValue('amount'),
              'currencyCode': r.getStringValue('currency_code'),
              'date': _decodeDate(r.getStringValue('date')),
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
              'hlc': r.getStringValue('hlc'), // AGGIUNTO
              'isDeleted': r.getBoolValue('is_deleted'), // AGGIUNTO
              'isSynced': true,
            },
          )
          .toList();

      final packet = SyncPacket(
        senderUserId: _identity.uuid,
        sinceHlc: sinceHlc,
        users: usersJson,
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

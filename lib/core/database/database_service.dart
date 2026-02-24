import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'database.dart';

import 'package:smezza/core/security/identity_manager.dart';
  
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final AppDatabase _database = AppDatabase();
  Future<void> close() => _database.close();

  /// *********************
  ///  User 
  /// *********************
  
  Future<void> createUser(String name, {String? avatarPath, bool isMe = true}) async{

    await IdentityManager.init();

    final id = IdentityManager.uuid;
    final now = DateTime.now();
    final hlc = '${now.millisecondsSinceEpoch}:0001:local';

    await _database.into(_database.users).insert(
          UsersCompanion.insert(
            id: id,
            name: name,
            hlc: hlc,
            avatarPath: Value(avatarPath),
            isMe: Value(isMe),
          ),
        );
  }

  Future<List<User>> fetchUsers() => _database.select(_database.users).get();

  Future<void> deleteUser(String id) {
    return (_database.delete(_database.users)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// *********************
  ///  Group
  /// *********************
  
  Future<void> createGroup(String ownerId, String name, {String? description}) async {
    final groupId = const Uuid().v4();
    final now = DateTime.now();
    final hlc = '${now.millisecondsSinceEpoch}:0001:local';
    final message = '$groupId|$ownerId|$name|$hlc';
    final signature = await IdentityManager.sign(message);
    
    await _database.into(_database.groups).insert(
          GroupsCompanion.insert(
            id: groupId,
            ownerId: ownerId,
            name: name,
            description: Value(description),
            createdAt: now.millisecondsSinceEpoch,
            hlc: hlc,
            signature: signature,
          ),
        );

    await _database.into(_database.groupMembers).insert(
          GroupMembersCompanion.insert(
            id: const Uuid().v4(),
            groupId: groupId,
            userId: ownerId,
            role: 'OWNER',
            authorizedBy: ownerId,
            hlc: hlc,
            signature: signature,
          ),
        );
  }

  Future<List<Group>> fetchGroups() => _database.select(_database.groups).get();

  Future<void> deleteGroup(String id) {
    return (_database.delete(_database.groups)..where((tbl) => tbl.id.equals(id))).go();
  }
}

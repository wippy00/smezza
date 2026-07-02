import 'dart:convert';

class SyncPacket {
  final String senderUserId;
  final String sinceHlc;
  final List<Map<String, dynamic>> users;
  final List<Map<String, dynamic>> groups;
  final List<Map<String, dynamic>> expenses;
  final List<Map<String, dynamic>> splits;

  const SyncPacket({
    required this.senderUserId,
    required this.sinceHlc,
    this.users = const [],
    this.groups = const [],
    this.expenses = const [],
    this.splits = const [],
  });

  bool get isEmpty =>
      users.isEmpty && groups.isEmpty && expenses.isEmpty && splits.isEmpty;

  String toJsonString() => jsonEncode({
    'senderUserId': senderUserId,
    'sinceHlc': sinceHlc,
    'users': users,
    'groups': groups,
    'expenses': expenses,
    'splits': splits,
  });

  factory SyncPacket.fromJsonString(String s) {
    final j = jsonDecode(s);
    return SyncPacket(
      senderUserId: j['senderUserId'],
      sinceHlc: j['sinceHlc'],
      users: List<Map<String, dynamic>>.from(j['users'] ?? []),
      groups: List<Map<String, dynamic>>.from(j['groups'] ?? []),
      expenses: List<Map<String, dynamic>>.from(j['expenses'] ?? []),
      splits: List<Map<String, dynamic>>.from(j['splits'] ?? []),
    );
  }
}

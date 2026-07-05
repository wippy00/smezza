import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import '../../../data/database.dart';

final paymentsProvider =
    StreamProvider.family<List<PaymentsTableData>, String>((ref, groupId) {
      final db = GetIt.I<AppDatabase>();
      return db.paymentsDao.watchByGroup(groupId);
    });
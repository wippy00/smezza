import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import '/core/identity/identity_manager.dart';

final needsBackupProvider = FutureProvider<bool>((ref) async {
  final identity = GetIt.I<IdentityService>();
  final done = await identity.isBackupConfirmed();
  return !done;
});

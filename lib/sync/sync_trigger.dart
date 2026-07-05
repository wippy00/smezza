import 'package:get_it/get_it.dart';
import '../../sync/sync_service.dart';

void triggerSync() {
  GetIt.I<SyncService>().sync();
}

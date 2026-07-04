import 'push_result.dart';
import 'sync_packet.dart';

enum SyncStatus { connected, syncing, disconnected, error }

abstract class SyncRepository {
  /// Spedisce i dati locali non ancora sincronizzati al server.
  /// Non lancia più eccezione se UN record fallisce: prova tutti gli altri
  /// e riporta nel risultato chi è andato a buon fine e chi no.
  Future<PushResult> push(SyncPacket packet);

  Future<SyncPacket?> pull({required String sinceHlc});

  Stream<SyncStatus> get statusStream;

  Future<void> dispose();
}
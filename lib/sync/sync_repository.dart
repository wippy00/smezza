import 'sync_packet.dart';

enum SyncStatus { connected, syncing, disconnected, error }

abstract class SyncRepository {
  /// Spedisce i dati locali non ancora sincronizzati al server
  Future<void> push(SyncPacket packet);

  /// Recupera i dati remoti aggiornati a partire da un certo HLC
  Future<SyncPacket?> pull({required String sinceHlc});

  /// Permette alla UI di ascoltare in tempo reale lo stato della connessione
  Stream<SyncStatus> get statusStream;

  Future<void> dispose();
}

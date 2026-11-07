enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

class SyncState {
  final SyncStatus status;
  final DateTime? lastSyncTime;
  final String? message;
  final int syncedCount;

  const SyncState({
    this.status = SyncStatus.idle,
    this.lastSyncTime,
    this.message,
    this.syncedCount = 0,
  });

  bool get isSyncing => status == SyncStatus.syncing;

  SyncState copyWith({
    SyncStatus? status,
    DateTime? Function()? lastSyncTime,
    String? Function()? message,
    int? syncedCount,
  }) {
    return SyncState(
      status: status ?? this.status,
      lastSyncTime: lastSyncTime != null ? lastSyncTime() : this.lastSyncTime,
      message: message != null ? message() : this.message,
      syncedCount: syncedCount ?? this.syncedCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          lastSyncTime == other.lastSyncTime &&
          message == other.message &&
          syncedCount == other.syncedCount;

  @override
  int get hashCode =>
      status.hashCode ^ lastSyncTime.hashCode ^ message.hashCode ^ syncedCount.hashCode;
}
